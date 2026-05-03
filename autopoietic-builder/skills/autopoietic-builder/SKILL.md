---
name: autopoietic-builder
description: Use when the user asks to scaffold a new skill or agent that should grow new capabilities on demand within a defined scope (e.g., "make me a Jira skill that learns", "build a Stripe assistant that extends itself", or any request to scaffold a domain-bounded helper that should cache its own reference material instead of relying on web search every invocation).
license: MIT
compatibility: Designed for Claude Code; the portable scaffolder script works in any environment with POSIX shell. Generated skills target the agentskills.io specification and run in any harness honoring AGENTS.md and SKILL.md.
metadata:
  version: "1.0"
  spec: agentskills.io/specification
allowed-tools: Read Write Edit Glob Grep Bash WebFetch
---

# Autopoietic Builder

## What this skill does

Scaffolds a self-contained, mission-bounded skill or agent that:

- Defines its own scope in `mission.md`
- Caches its reference knowledge inside its own folder
- Uses progressive disclosure (thin SKILL.md, deep references on demand)
- Mutates itself when an in-mission request lands outside its current capability index — pausing the original task, learning the new capability via a background subagent, asking the user for confirmation once, then resuming and completing the original task

Each generated skill conforms to the [agentskills.io specification](https://agentskills.io/specification) and to the self-containment rules in `references/architecture.md`.

## Reference layout

The full architecture and templates: see [references/architecture.md](references/architecture.md). It is the single source of truth for both the in-CC scaffolding workflow described below and the portable shell scaffolder at `<plugin-root>/bin/scaffold-autopoietic-skill`.

Conceptual primitives:
- [references/mission-design.md](references/mission-design.md) — how to write `mission.md` (domain, in-scope, out-of-scope, action classes)
- [references/architecture.md](references/architecture.md) — directory layout, frontmatter, template fenced blocks
- [references/growth-protocol.md](references/growth-protocol.md) — the runtime self-mutation flow (copied into every generated skill)
- [references/anti-poisoning.md](references/anti-poisoning.md) — source-tier rules, provenance schema (copied)
- [references/verification-recipes.md](references/verification-recipes.md) — sandbox/dry-run/describe-only patterns by action class (copied)
- [references/resume-state.md](references/resume-state.md) — journal format, crash recovery (copied)

The runtime actor:
- [agents/capability-learner.md](agents/capability-learner.md) — the subagent dispatched at growth time

## Scaffolding workflow (invoked by `/new-autopoietic-skill <name> "<mission>"`)

1. **Validate inputs.**
   - `<name>` must satisfy the spec name rules: 1–64 chars, lowercase + hyphens, no leading/trailing/consecutive hyphens. Reject malformed names with the specific rule that failed.
   - `<mission>` must be a non-empty string of 1–3 sentences. If shorter, ask the user to elaborate; if longer, ask them to trim. Mission domain comes from this string; in-scope and out-of-scope are filled interactively.

2. **Interview for mission completeness** (per [references/mission-design.md](references/mission-design.md)):
   - Confirm the **domain** (system, instance, auth boundary)
   - Elicit **in-scope** intent shapes (3–8 bullets, each a shape not a single capability)
   - Elicit **out-of-scope** adjacent temptations (3–5 bullets, each named explicitly)
   - Confirm or override the default **action class** policy

   If the user is confident and dictates these in one shot, accept and proceed. Otherwise ask them sequentially. Stop interviewing once the four pieces above exist.

3. **Pick a target directory.** Default `~/.claude/skills/<name>` for personal skills, or a project-relative path if the user specified one. Confirm with the user before writing.

4. **Render templates.** Read [references/architecture.md](references/architecture.md). For each fenced block marked `<!-- TEMPLATE: <relative-path> -->`, substitute the placeholder allowlist (see architecture.md for the full list) and write to `<target-dir>/<name>/<relative-path>`. Compute `mission_hash` after rendering `mission.md` and write it back into `SKILL.md`'s frontmatter.

5. **Copy reference files unchanged.** Copy `growth-protocol.md`, `anti-poisoning.md`, `verification-recipes.md`, `resume-state.md` from this skill's `references/` directory into the new skill's `references/`. **No substitution.** These files must be byte-identical to enable later upgrade detection.

6. **Validate.** Run `skills-ref validate <target-dir>/<name>` if available. If the validator is not installed, surface a suggestion to install it; do not block scaffolding on missing tooling.

7. **Self-containment audit.** Run `grep -r 'autopoietic-builder:' <target-dir>/<name>` — must return nothing. The generated skill must be runnable with this meta-skill uninstalled.

8. **Report.** Show the user the new directory tree, the rendered SKILL.md, the mission summary, and the install command for their harness.

## Agent scaffolding workflow (invoked by `/new-autopoietic-agent <name> "<mission>"`)

The agent variant produces a subagent definition (markdown in `agents/`) that follows the same self-mutation discipline. The differences:

- The output is a single markdown file with frontmatter, not a directory tree
- The agent's mission is embedded in its body rather than in a separate `mission.md`
- Knowledge caching for an agent uses a sibling `<name>-knowledge/` directory (the agent's own folder analog)

For step-by-step, follow the same workflow above but render only the agent template from [references/architecture.md](references/architecture.md) (template marked `<!-- TEMPLATE: agents/<name>.md -->` if/when added; v1 of this skill scaffolds skill bundles, agent variant is a v1.1 follow-up — confirm with the user whether to use the skill workflow against an agent target or wait).

## Upgrade workflow (invoked by `/upgrade-autopoietic-skill <name>`)

When the meta-skill's `references/*.md` files have evolved and a previously-generated skill should pick up the new versions:

1. Locate the target skill (`<dir>/<name>/`).
2. Compute sha256 of each of the generated skill's four `references/*.md` files (growth-protocol, anti-poisoning, verification-recipes, resume-state). Compare against the meta-skill's current versions.
3. For each file that differs:
   - Show the user the diff
   - Ask: replace, keep, or merge interactively
4. After all decisions, update `metadata.autopoietic_version` in the target's `SKILL.md` to match this meta-skill's `metadata.version`.
5. Re-run `skills-ref validate` and the self-containment audit.

Never overwrite `mission.md`, `capabilities/*`, `cache/*`, or `learned/*` during upgrade — those are the skill's own knowledge.

## When not to use this skill

- The user wants a one-shot operation, not a reusable assistant. Do the operation directly.
- The user wants a documentation skill (no growth, no learning). Use [`superpowers:writing-skills`](../../../) instead — autopoietic overhead is wasted on a static skill.
- The user wants to scaffold something that can rewrite its own mission. That's mission drift; refuse and explain.

## Cross-references

- **Skill writing discipline (frontmatter, CSO trap, Iron Law):** REQUIRED BACKGROUND — `superpowers:writing-skills`
- **Test-driven authoring:** REQUIRED BACKGROUND — `superpowers:test-driven-development`
- **agentskills.io spec:** https://agentskills.io/specification (canonical) and https://github.com/agentskills/agentskills/tree/main/skills-ref (validator)
