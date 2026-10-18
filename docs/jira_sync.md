# Jira synchronization

The repository is the source of truth for the demo-level plan. The GitHub Action
in `.github/workflows/sync-jira.yml` synchronizes:

- `intent/demo-level/intent.md` to one **Demo Level** epic;
- every file in `intent/demo-level/issues/` to a story under that epic; and
- every acceptance-criteria checkbox to a subtask under its story.

Stable Jira labels identify generated work items, so later runs update them
instead of creating duplicates. The synchronizer updates summaries,
descriptions, hierarchy, and done/to-do status. It intentionally never deletes
or archives Jira work items when Markdown is removed.

## Required GitHub Actions secrets

Configure these under **Repository settings → Secrets and variables → Actions**:

- `JIRA_BASE_URL`, such as `https://example.atlassian.net`
- `JIRA_EMAIL`, the Atlassian account email associated with the API token
- `JIRA_API_TOKEN`
- `JIRA_PROJECT_KEY`, such as `EFB`

The API user must be able to browse the project, create and edit issues, create
subtasks, and transition issues. The Jira project must provide issue types named
`Epic`, `Story`, and `Sub-task`. Alternative names can be supplied through the
optional `JIRA_EPIC_TYPE`, `JIRA_STORY_TYPE`, and `JIRA_SUBTASK_TYPE`
environment variables in the workflow.

## Running it

The workflow runs automatically when relevant files are pushed to `main`. It
can also be started from **GitHub → Actions → Sync demo plan to Jira → Run
workflow** after the workflow exists on the default branch.

Validate the Markdown locally without contacting Jira:

```sh
python3 scripts/sync_jira.py --validate
python3 -m unittest tests/test_sync_jira.py
```

To link development activity to a synchronized story, include its Jira key in
the branch name, commit message, and pull-request title.
