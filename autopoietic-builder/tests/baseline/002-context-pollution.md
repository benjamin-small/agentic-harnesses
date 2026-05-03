# Baseline 002 — Context pollution from capability index

## Setup

Spawn a subagent with no growth protocol. Give it a skill bundle with many capability files and an INDEX:

```
jira-helper/
├── SKILL.md
├── capabilities/
│   ├── INDEX.md           # 20 rows
│   ├── list-issues.md     # 250 lines
│   ├── search-issues.md   # 280 lines
│   ├── get-issue.md       # 200 lines
│   ├── add-comment.md     # 220 lines
│   └── (16 more)
```

## Prompt

> List the 5 most recent issues in project ACME.

## Documented failure

Baseline subagents will typically:

- Read `INDEX.md` and **all** capability files, "to be thorough" or "to understand the available actions"
- Or, glob `capabilities/*.md` and load all matches before deciding
- Or, read the SKILL.md and cite all 20 capabilities back to the user before doing anything

Token usage on a simple "list 5 issues" task balloons by 5–20× the necessary footprint, and irrelevant patterns from other capability files leak into the response (e.g., issue creation flow appears in a list-issues response).

## Why it fails

Without an explicit progressive-disclosure rule (load **only** the matched INDEX row's file), agents under pressure to "be helpful" load broadly. The skill must forbid this explicitly.

## Pass criterion (RED)

3 baseline runs. At least 2 of 3 must read more than just `list-issues.md`. If all 3 honor progressive disclosure naturally, scenario is no longer pressure-bearing.
