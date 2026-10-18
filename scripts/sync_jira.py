#!/usr/bin/env python3
"""Synchronize the demo-level Markdown plan to Jira Cloud.

The repository is authoritative. Jira items are located with stable labels so
rerunning the script updates existing work rather than creating duplicates.
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any


SYNC_LABEL = "repo-sync-demo-level"
ISSUE_PATTERN = re.compile(r"^#\s+(\d+):\s+(.+)$", re.MULTILINE)
CHECKLIST_PATTERN = re.compile(r"^- \[([ xX])\]\s+(.+)$", re.MULTILINE)
FIELD_PATTERN = re.compile(r"^\*\*(.+?):\*\*\s*(.*)$", re.MULTILINE)


@dataclass(frozen=True)
class Criterion:
    number: int
    text: str
    done: bool


@dataclass(frozen=True)
class Story:
    number: str
    title: str
    source_story: str
    description: str
    blocked_by: str
    status: str
    criteria: tuple[Criterion, ...]
    source_path: str
    markdown: str

    @property
    def sync_label(self) -> str:
        return f"{SYNC_LABEL}-story-{self.number}"


def parse_story(path: Path, repository_root: Path | None = None) -> Story:
    markdown = path.read_text(encoding="utf-8")
    title_match = ISSUE_PATTERN.search(markdown)
    if title_match is None:
        raise ValueError(f"{path}: expected a '# NN: title' heading")

    fields = {name.strip().lower(): value.strip() for name, value in FIELD_PATTERN.findall(markdown)}
    missing = [name for name in ("source story", "what to build", "blocked by", "status") if name not in fields]
    if missing:
        raise ValueError(f"{path}: missing fields: {', '.join(missing)}")

    criteria = tuple(
        Criterion(number=index, text=text.strip(), done=marker.lower() == "x")
        for index, (marker, text) in enumerate(CHECKLIST_PATTERN.findall(markdown), start=1)
    )
    if not criteria:
        raise ValueError(f"{path}: expected at least one acceptance checklist item")

    source_path = str(path)
    if repository_root is not None:
        source_path = str(path.relative_to(repository_root))

    return Story(
        number=title_match.group(1),
        title=title_match.group(2).strip(),
        source_story=fields["source story"],
        description=fields["what to build"],
        blocked_by=fields["blocked by"],
        status=fields["status"].lower(),
        criteria=criteria,
        source_path=source_path,
        markdown=markdown,
    )


def load_stories(intent_root: Path, repository_root: Path | None = None) -> list[Story]:
    stories = [parse_story(path, repository_root) for path in sorted((intent_root / "issues").glob("*.md"))]
    if not stories:
        raise ValueError(f"No story files found under {intent_root / 'issues'}")
    numbers = [story.number for story in stories]
    if len(numbers) != len(set(numbers)):
        raise ValueError("Story numbers must be unique")
    return stories


def jira_document(text: str) -> dict[str, Any]:
    content = []
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        content.append({"type": "paragraph", "content": [{"type": "text", "text": stripped}]})
    if not content:
        content.append({"type": "paragraph", "content": [{"type": "text", "text": " "}]})
    return {"type": "doc", "version": 1, "content": content}


def story_description(story: Story) -> str:
    return (
        f"Source: {story.source_path}\n"
        f"Source story: {story.source_story}\n"
        f"Blocked by: {story.blocked_by}\n\n"
        f"{story.description}"
    )


def criterion_description(story: Story, criterion: Criterion) -> str:
    return (
        f"Acceptance criterion {criterion.number} for story {story.number}.\n"
        f"Source: {story.source_path}\n\n"
        f"{criterion.text}"
    )


class JiraClient:
    def __init__(self, base_url: str, email: str, api_token: str, project_key: str) -> None:
        self.base_url = base_url.rstrip("/")
        self.project_key = project_key.upper()
        if not re.fullmatch(r"[A-Z][A-Z0-9_]*", self.project_key):
            raise ValueError("JIRA_PROJECT_KEY contains unsupported characters")
        credentials = base64.b64encode(f"{email}:{api_token}".encode()).decode()
        self.headers = {
            "Accept": "application/json",
            "Authorization": f"Basic {credentials}",
            "Content-Type": "application/json",
        }
        self._issue_types: list[dict[str, Any]] | None = None

    def request(self, method: str, path: str, payload: dict[str, Any] | None = None) -> Any:
        body = None if payload is None else json.dumps(payload).encode("utf-8")
        request = urllib.request.Request(
            f"{self.base_url}/rest/api/3{path}",
            data=body,
            headers=self.headers,
            method=method,
        )
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                response_body = response.read()
                return json.loads(response_body) if response_body else None
        except urllib.error.HTTPError as error:
            details = error.read().decode("utf-8", errors="replace")
            raise RuntimeError(f"Jira {method} {path} failed ({error.code}): {details}") from error

    def find_by_label(self, label: str) -> dict[str, Any] | None:
        result = self.request(
            "POST",
            "/search/jql",
            {
                "jql": f'project = "{self.project_key}" AND labels = "{label}"',
                "fields": ["summary", "status", "labels"],
                "maxResults": 2,
            },
        )
        issues = result.get("issues", [])
        if len(issues) > 1:
            raise RuntimeError(f"Multiple Jira items use synchronization label {label}")
        return issues[0] if issues else None

    def issue_types(self) -> list[dict[str, Any]]:
        if self._issue_types is None:
            result = self.request("GET", f"/issue/createmeta/{urllib.parse.quote(self.project_key)}/issuetypes")
            self._issue_types = result.get("issueTypes", [])
        return self._issue_types

    def resolve_issue_type(self, role: str, configured_name: str | None = None) -> str:
        issue_types = self.issue_types()
        if configured_name:
            candidates = [item for item in issue_types if item.get("name", "").lower() == configured_name.lower()]
        elif role == "epic":
            candidates = [item for item in issue_types if item.get("name", "").lower() == "epic"]
            if not candidates:
                candidates = [item for item in issue_types if item.get("hierarchyLevel") == 1]
        elif role == "story":
            candidates = [item for item in issue_types if item.get("name", "").lower() == "story"]
            if not candidates:
                candidates = [
                    item for item in issue_types
                    if not item.get("subtask", False) and item.get("hierarchyLevel", 0) == 0
                ]
        else:
            candidates = [item for item in issue_types if item.get("subtask", False)]

        if not candidates:
            available = ", ".join(item.get("name", "unknown") for item in issue_types)
            requested = configured_name or role
            raise RuntimeError(f"No Jira issue type found for {requested}; available types: {available}")
        return candidates[0]["name"]

    def epic_name_field(self, issue_type: str) -> str | None:
        matching_types = [item for item in self.issue_types() if item.get("name") == issue_type]
        if not matching_types:
            return None
        result = self.request(
            "GET",
            f"/issue/createmeta/{urllib.parse.quote(self.project_key)}/issuetypes/"
            f"{urllib.parse.quote(str(matching_types[0]['id']))}",
        )
        for field in result.get("fields", []):
            if field.get("required") and field.get("name", "").lower() == "epic name":
                return field.get("fieldId") or field.get("key")
        return None

    def upsert_issue(
        self,
        *,
        label: str,
        summary: str,
        description: str,
        issue_type: str,
        parent_key: str | None = None,
    ) -> dict[str, Any]:
        create_fields: dict[str, Any] = {
            "project": {"key": self.project_key},
            "summary": summary[:255],
            "description": jira_document(description),
            "issuetype": {"name": issue_type},
            "labels": [SYNC_LABEL, label],
        }
        if parent_key is not None:
            create_fields["parent"] = {"key": parent_key}

        existing = self.find_by_label(label)
        if existing is None:
            if parent_key is None:
                epic_name_field = self.epic_name_field(issue_type)
                if epic_name_field:
                    create_fields[epic_name_field] = summary[:255]
            created = self.request("POST", "/issue", {"fields": create_fields})
            print(f"Created {created['key']}: {summary}")
            return self.get_issue(created["key"])

        key = existing["key"]
        existing_labels = existing.get("fields", {}).get("labels", [])
        update_fields: dict[str, Any] = {
            "summary": summary[:255],
            "description": jira_document(description),
            "labels": sorted(set(existing_labels + [SYNC_LABEL, label])),
        }
        if parent_key is not None:
            update_fields["parent"] = {"key": parent_key}
        self.request("PUT", f"/issue/{urllib.parse.quote(key)}", {"fields": update_fields})
        print(f"Updated {key}: {summary}")
        return self.get_issue(key)

    def get_issue(self, key: str) -> dict[str, Any]:
        return self.request("GET", f"/issue/{urllib.parse.quote(key)}?fields=status")

    def set_done_state(self, issue: dict[str, Any], done: bool) -> None:
        current_category = issue["fields"]["status"]["statusCategory"]["key"]
        desired_category = "done" if done else "new"
        if current_category == desired_category:
            return

        transitions = self.request("GET", f"/issue/{urllib.parse.quote(issue['key'])}/transitions")
        for transition in transitions.get("transitions", []):
            target_category = transition.get("to", {}).get("statusCategory", {}).get("key")
            if target_category == desired_category:
                self.request(
                    "POST",
                    f"/issue/{urllib.parse.quote(issue['key'])}/transitions",
                    {"transition": {"id": transition["id"]}},
                )
                print(f"Transitioned {issue['key']} to {transition['to']['name']}")
                return

        print(
            f"::warning::No available transition from {issue['fields']['status']['name']} "
            f"to category {desired_category} for {issue['key']}",
            file=sys.stderr,
        )


def synchronize(client: JiraClient, intent_root: Path, repository_root: Path) -> None:
    stories = load_stories(intent_root, repository_root)
    intent_path = intent_root / "intent.md"
    intent_markdown = intent_path.read_text(encoding="utf-8")
    game_epic_type = client.resolve_issue_type("epic", os.getenv("JIRA_EPIC_TYPE"))
    story_type = client.resolve_issue_type("story", os.getenv("JIRA_STORY_TYPE"))
    subtask_type = client.resolve_issue_type("subtask", os.getenv("JIRA_SUBTASK_TYPE"))
    epic = client.upsert_issue(
        label=f"{SYNC_LABEL}-epic",
        summary="Demo Level",
        description=f"Source: {intent_path.relative_to(repository_root)}\n\n{intent_markdown}",
        issue_type=game_epic_type,
    )

    all_stories_done = True
    for story in stories:
        story_issue = client.upsert_issue(
            label=story.sync_label,
            summary=f"{story.number}: {story.title}",
            description=story_description(story),
            issue_type=story_type,
            parent_key=epic["key"],
        )
        story_done = story.status == "done"
        all_stories_done = all_stories_done and story_done
        client.set_done_state(story_issue, story_done)

        for criterion in story.criteria:
            criterion_label = f"{story.sync_label}-criterion-{criterion.number:02d}"
            criterion_issue = client.upsert_issue(
                label=criterion_label,
                summary=criterion.text,
                description=criterion_description(story, criterion),
                issue_type=subtask_type,
                parent_key=story_issue["key"],
            )
            client.set_done_state(criterion_issue, criterion.done)

    client.set_done_state(epic, all_stories_done)
    print(f"Synchronized 1 epic, {len(stories)} stories, and {sum(len(s.criteria) for s in stories)} subtasks")


def required_environment(name: str) -> str:
    value = os.getenv(name, "").strip()
    if not value:
        raise ValueError(f"Missing required environment variable: {name}")
    return value


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--validate", action="store_true", help="Parse files without contacting Jira")
    parser.add_argument("--intent-root", type=Path, default=Path("intent/demo-level"))
    arguments = parser.parse_args()

    repository_root = Path(__file__).resolve().parents[1]
    intent_root = arguments.intent_root
    if not intent_root.is_absolute():
        intent_root = repository_root / intent_root

    stories = load_stories(intent_root, repository_root)
    if arguments.validate:
        print(
            f"Validated 1 epic, {len(stories)} stories, "
            f"and {sum(len(story.criteria) for story in stories)} subtasks"
        )
        return 0

    client = JiraClient(
        required_environment("JIRA_BASE_URL"),
        required_environment("JIRA_EMAIL"),
        required_environment("JIRA_API_TOKEN"),
        required_environment("JIRA_PROJECT_KEY"),
    )
    synchronize(client, intent_root, repository_root)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, ValueError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        raise SystemExit(1)
