---
description: Upgrade a previously-scaffolded autopoietic skill to the current version of the autopoietic-builder protocol — re-copies the bundled references and bumps the metadata version
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

Use the `autopoietic-builder` skill to upgrade a previously-scaffolded autopoietic skill.

Args from the user invocation: `$ARGUMENTS`

Expected shape: `<skill-name>` or a path to the skill directory.

Follow the **Upgrade workflow** in `skills/autopoietic-builder/SKILL.md`. Do not modify `mission.md`, `capabilities/`, `cache/`, or `learned/` — those are the skill's own knowledge and are upgraded through their own protocols (re-learning, cache TTL refresh), not through this command.

If the target skill cannot be located, ask the user for the path. If it does not appear to be an autopoietic skill (no `metadata.scaffolded_by: autopoietic-builder` in `SKILL.md`), refuse and explain.
