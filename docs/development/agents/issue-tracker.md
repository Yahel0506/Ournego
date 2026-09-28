# Issue Tracker: GitHub

Issues and PRDs for this repo live as GitHub issues. Use the `gh` CLI for all issue-tracker operations.

## Conventions

- Create an issue with `gh issue create --title "..." --body "..."`.
- Read an issue with `gh issue view <number> --comments`.
- List issues with `gh issue list --state open`.
- Comment on an issue with `gh issue comment <number> --body "..."`.
- Add or remove labels with `gh issue edit <number> --add-label "..."` and `--remove-label "..."`.
- Close an issue with `gh issue close <number> --comment "..."`.

## Skill behavior

- When a skill says "publish to the issue tracker", create a GitHub issue.
- When a skill says "fetch the relevant ticket", use `gh issue view`.
- Infer the repository from the current clone; `gh` handles that automatically when run inside the repo.
