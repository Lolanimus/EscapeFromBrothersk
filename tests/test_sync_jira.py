import tempfile
import unittest
from pathlib import Path

from scripts.sync_jira import jira_document, load_stories, parse_story, story_description


SAMPLE_STORY = """# 07: Collect magazines

**Source story:** 7

**What to build:** As a player, I want ammunition.

**Blocked by:** 02: Acquire pistol.

**Status:** done

- [x] Pistol magazines contain 12 bullets.
- [ ] Magazine pickups are visible.
"""


class StoryParserTests(unittest.TestCase):
    def test_parses_story_and_acceptance_criteria(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = root / "07-collect-magazines.md"
            path.write_text(SAMPLE_STORY, encoding="utf-8")

            story = parse_story(path, root)

        self.assertEqual("07", story.number)
        self.assertEqual("Collect magazines", story.title)
        self.assertEqual("done", story.status)
        self.assertTrue(story.description.startswith("As a player, I want"))
        self.assertEqual("07-collect-magazines.md", story.source_path)
        self.assertEqual(2, len(story.criteria))
        self.assertTrue(story.criteria[0].done)
        self.assertFalse(story.criteria[1].done)
        self.assertEqual("repo-sync-demo-level-story-07", story.sync_label)
        self.assertIn("Repository title: 07: Collect magazines", story_description(story))

    def test_rejects_duplicate_story_numbers(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            issues = root / "issues"
            issues.mkdir()
            (issues / "first.md").write_text(SAMPLE_STORY, encoding="utf-8")
            (issues / "second.md").write_text(SAMPLE_STORY, encoding="utf-8")

            with self.assertRaisesRegex(ValueError, "must be unique"):
                load_stories(root, root)

    def test_builds_atlassian_document_format(self):
        document = jira_document("First paragraph\n\nSecond paragraph")

        self.assertEqual("doc", document["type"])
        self.assertEqual(1, document["version"])
        self.assertEqual("First paragraph", document["content"][0]["content"][0]["text"])
        self.assertEqual("Second paragraph", document["content"][1]["content"][0]["text"])


if __name__ == "__main__":
    unittest.main()
