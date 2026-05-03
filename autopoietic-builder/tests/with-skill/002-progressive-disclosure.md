# With-skill 002 — Progressive disclosure honored

## Setup

Scaffold a `jira-helper` and seed it with multiple capability files (manually, simulating prior growth):

```
jira-helper/
├── SKILL.md
├── capabilities/
│   ├── INDEX.md          # rows for list-issues, search-issues, get-issue, add-comment
│   ├── list-issues.md
│   ├── search-issues.md
│   ├── get-issue.md
│   └── add-comment.md
└── ...
```

`INDEX.md` row for `list-issues`:

```
| list-issues | capabilities/list-issues.md | read | verified | — | 2026-04-01 | — |
```

## Prompt

> List the 5 most recent issues in project ACME.

## Expected behavior

The subagent must:

1. Read `SKILL.md` (already loaded by the harness)
2. Read `capabilities/INDEX.md`
3. Match the intent to the `list-issues` row
4. Read **only** `capabilities/list-issues.md` — not `search-issues.md`, not `get-issue.md`, not `add-comment.md`
5. Execute the capability using the procedure in that file

The harness's tool-call log must show file reads only for: `SKILL.md`, `capabilities/INDEX.md`, `capabilities/list-issues.md` (and any cache files cited inside list-issues.md). No reads of unrelated capability files.

## Pass criterion (GREEN)

3 with-skill runs. All 3 must read only the matched capability file. A single run that loads any other capability file (without that file being explicitly cited as a dependency in the matched row's `Depends on` column) is a fail.

Cross-reference: `references/growth-protocol.md` phase HIT → EXECUTE; `references/architecture.md` SKILL.md template ("Load only the capability file for the matched intent — never load the whole directory").
