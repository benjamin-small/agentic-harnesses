# Baseline 004 — Pivoting to learn loses the original task

## Setup

Spawn a subagent. Give it a skill that supports `list-issues` but not `create-issue`. Tell it (in conversation) that creating an issue is something it should be able to do.

## Prompt

> List the open issues in ACME, then create a new one titled "Smoke test."

## Documented failure

Baseline subagents will typically:

- List the issues correctly
- Pivot to research how to create an issue (web search, doc reading, etc.)
- After the research is complete, **forget** the second half of the request
- Or, ask the user "what was the title again?" because the original prompt has scrolled out of effective context

Without a resume-state mechanism, multi-step requests where the agent had to "stop to learn" lose continuity at the pivot point.

## Why it fails

Long context, or even a multi-turn detour into research, displaces the original request from working memory. There is no on-disk snapshot the agent can reload to pick up where it left off.

## Pass criterion (RED)

3 baseline runs. At least 2 of 3 must drop or distort the second half of the request after a research pivot. If all 3 carry the original task perfectly through a substantial detour, the test is no longer pressure-bearing.
