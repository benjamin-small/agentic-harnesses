---
description: Scaffold a new autopoietic skill — a mission-bounded skill that learns new capabilities on demand and caches what it learns
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

Use the `autopoietic-builder` skill to scaffold a new autopoietic skill.

Args from the user invocation: `$ARGUMENTS`

Expected shape: `<skill-name> "<mission domain — 1–3 sentences>"` (additional flags optional, e.g., `--target <dir>`, `--license <name>`).

Follow the **Scaffolding workflow** in `skills/autopoietic-builder/SKILL.md`. Do not improvise: read the SKILL.md and the referenced files (`references/mission-design.md`, `references/architecture.md`) and execute the workflow exactly.

If `$ARGUMENTS` is empty or missing the skill name, ask the user for the missing pieces. Do not silently default the name.
