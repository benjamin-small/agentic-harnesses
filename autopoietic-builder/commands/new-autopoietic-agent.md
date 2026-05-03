---
description: Scaffold a new autopoietic subagent — a mission-bounded subagent that learns and caches knowledge alongside its definition
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

Use the `autopoietic-builder` skill to scaffold a new autopoietic subagent.

Args from the user invocation: `$ARGUMENTS`

Expected shape: `<agent-name> "<mission domain — 1–3 sentences>"` (additional flags optional).

Follow the **Agent scaffolding workflow** in `skills/autopoietic-builder/SKILL.md`. The agent variant produces a single subagent definition file plus a sibling knowledge directory (rather than a full skill bundle).

If the agent variant is not yet supported in this version of `autopoietic-builder`, surface that to the user and offer to scaffold a skill bundle instead — explain that the skill bundle can act as the knowledge backing for a subagent, and how to wire the two together.

If `$ARGUMENTS` is empty or missing the agent name, ask the user for the missing pieces.
