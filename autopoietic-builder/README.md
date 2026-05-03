# autopoietic-builder

Scaffolds **autopoietic skills**: domain-bounded helpers that

1. Define their own scope in `mission.md` and refuse out-of-scope requests cleanly
2. Cache their reference knowledge inside their own folder, not on the open web
3. Use progressive disclosure (thin `SKILL.md`, deep references loaded on demand)
4. **Mutate themselves** when an in-scope request lands outside their current capability index — pausing the original task, learning the new capability via a background subagent, asking the user once for confirmation, then resuming the original task seamlessly

Each generated skill is **self-contained**: it carries its own copy of the growth protocol, anti-poisoning rules, verification recipes, and resume-state machine. It runs in any harness honoring [agentskills.io](https://agentskills.io/specification) — Claude Code, Codex, Cursor, Aider, etc. — without needing this meta-skill installed.

## Install (Claude Code)

```bash
# Clone the parent repo
git clone https://github.com/benjamin-small/agentic-harnesses ~/dev/agentic-harnesses

# Symlink the autopoietic-builder plugin into your CC plugins directory
ln -s ~/dev/agentic-harnesses/autopoietic-builder ~/.claude/plugins/autopoietic-builder
```

After a fresh CC session, `/new-autopoietic-skill`, `/new-autopoietic-agent`, and `/upgrade-autopoietic-skill` appear in the slash-command list.

## Install (any other harness)

The portable POSIX scaffolder works without Claude Code:

```bash
~/dev/agentic-harnesses/autopoietic-builder/bin/scaffold-autopoietic-skill \
    jira-helper \
    --mission "Read and modify issues in the Jira Cloud ACME project, API-token auth." \
    --target ~/.agents/skills
```

The generated skill bundle is self-contained — no runtime dependency on this plugin.

## Quick start

```bash
# 1. Scaffold
/new-autopoietic-skill jira-helper "Read and modify issues in Jira Cloud, ACME project, API-token auth."

# 2. Edit the in-scope and out-of-scope bullets in the generated mission.md
# 3. Drop the new skill into your harness's skill directory
# 4. Use it — it grows new capabilities the first time you ask for one within mission scope
```

## Mental model

A traditional skill is a frozen reference. A generated skill from this scaffolder is a **closed-but-growing** reference: closed at the mission boundary (refuses out-of-scope), growing inside it (acquires new capabilities as needed).

The closure is what makes it safe to grow. The growth is what makes it stay useful as APIs evolve and weaker models replace stronger ones.

## What's in the box

| Path | Purpose |
|------|---------|
| `.claude-plugin/plugin.json` | CC plugin manifest |
| `commands/new-autopoietic-skill.md` | `/new-autopoietic-skill` dispatcher |
| `commands/new-autopoietic-agent.md` | `/new-autopoietic-agent` dispatcher |
| `commands/upgrade-autopoietic-skill.md` | `/upgrade-autopoietic-skill` dispatcher |
| `skills/autopoietic-builder/SKILL.md` | The meta-skill: how to scaffold |
| `skills/autopoietic-builder/references/architecture.md` | **Single source of truth** for the generated-skill layout — templates as fenced blocks |
| `skills/autopoietic-builder/references/mission-design.md` | How to write `mission.md` |
| `skills/autopoietic-builder/references/growth-protocol.md` | Runtime self-mutation flow (copied into every generated skill) |
| `skills/autopoietic-builder/references/anti-poisoning.md` | Source-tier rules, provenance schema (copied) |
| `skills/autopoietic-builder/references/verification-recipes.md` | Sandbox/dry-run/describe-only patterns by action class (copied) |
| `skills/autopoietic-builder/references/resume-state.md` | Journal format, crash recovery (copied) |
| `skills/autopoietic-builder/agents/capability-learner.md` | The subagent dispatched at growth time |
| `bin/scaffold-autopoietic-skill` | Portable POSIX scaffolder |
| `tests/baseline/` | TDD-for-skills RED scenarios (failures without the skill) |
| `tests/with-skill/` | TDD-for-skills GREEN scenarios (behaviors the skill must produce) |

## Validation

Generated skills follow the [agentskills.io specification](https://agentskills.io/specification). Validate any skill (generated or hand-edited) with:

```bash
skills-ref validate <skill-dir>
```

The scaffolder runs this automatically if `skills-ref` is on the `PATH`. Install: <https://github.com/agentskills/agentskills/tree/main/skills-ref>.

## Self-containment audit

Every generated skill must run with this plugin **uninstalled**. Verify:

```bash
grep -r 'autopoietic-builder:' <skill-dir>
# expect: no output
```

The scaffolder runs this audit automatically and refuses to finish if it fails.

## Upgrade path

When this plugin's `references/*.md` files evolve, run:

```
/upgrade-autopoietic-skill <name>
```

The command shows diffs and lets you replace, keep, or merge each reference per-file. It never touches `mission.md`, `capabilities/`, `cache/`, or `learned/` — those are the skill's own knowledge.

## Reading order for contributors

1. [skills/autopoietic-builder/SKILL.md](skills/autopoietic-builder/SKILL.md) — the meta-skill itself
2. [skills/autopoietic-builder/references/mission-design.md](skills/autopoietic-builder/references/mission-design.md) — the conceptual primitive
3. [skills/autopoietic-builder/references/architecture.md](skills/autopoietic-builder/references/architecture.md) — what gets generated
4. [skills/autopoietic-builder/references/growth-protocol.md](skills/autopoietic-builder/references/growth-protocol.md) — the runtime behavior
5. [tests/](tests/) — pressure scenarios that must pass (with-skill) and fail (baseline)

## License

MIT — see the parent repo's LICENSE if present, otherwise treat as MIT.
