# Generated-Skill Architecture (single source of truth)

This file defines **what a scaffolded autopoietic skill looks like on disk**. Both the in-CC scaffolding flow (driven by `SKILL.md`) and the portable POSIX scaffolder (`bin/scaffold-autopoietic-skill`) read their templates from the fenced code blocks below. There is exactly one copy of each template, and it lives here.

## Directory tree

```
<target-dir>/<skill-name>/
├── SKILL.md
├── AGENTS.md
├── mission.md
├── .gitignore
├── references/
│   ├── growth-protocol.md         # COPIED at scaffold time
│   ├── anti-poisoning.md          # COPIED at scaffold time
│   ├── verification-recipes.md    # COPIED at scaffold time
│   └── resume-state.md            # COPIED at scaffold time
├── capabilities/
│   └── INDEX.md
├── cache/
│   └── INDEX.md
├── learned/
│   └── README.md
├── tests/
│   ├── baseline/
│   │   └── README.md
│   └── growth/
│       └── README.md
└── .state/                         # gitignored, transient
    └── .gitkeep
```

The `references/*.md` files are not templates — they are **copied byte-for-byte** from this plugin's `skills/autopoietic-builder/references/` directory at scaffold time. That keeps each generated skill self-contained: it carries its own copy of the protocol, anti-poisoning rules, verification recipes, and state machine.

## Placeholder substitution

Every template uses `${VAR}` placeholders. The scaffolder substitutes only this allowlist (no other `${...}` is touched):

| Placeholder | Source |
|-------------|--------|
| `${SKILL_NAME}` | CLI arg / scaffold prompt |
| `${SKILL_TITLE}` | Title-cased version of `${SKILL_NAME}` |
| `${SKILL_DESCRIPTION}` | User-supplied; agentskills.io spec: ≤1024 chars, says what + when |
| `${MISSION_DOMAIN}` | User-supplied 1–3 sentences |
| `${MISSION_IN_SCOPE}` | Newline-separated bullets, each line `- <intent shape>` |
| `${MISSION_OUT_OF_SCOPE}` | Newline-separated bullets, each line `- <excluded system / why>` |
| `${LICENSE}` | Default `Proprietary`; user may override |
| `${COMPATIBILITY}` | Default `Designed for Claude Code; runs in any harness honoring AGENTS.md and the agentskills.io spec.` |
| `${ALLOWED_TOOLS}` | Default `Read Glob Grep`; learner subagent adds tools as capabilities are accepted |
| `${AUTOPOIETIC_VERSION}` | Read from this plugin's `plugin.json` |
| `${MISSION_HASH}` | sha256 of the rendered mission.md, computed after substitution |
| `${CREATED_AT}` | ISO-8601 timestamp |

Substitution is exclusively `envsubst '<allowlist>'` (POSIX) — no other variables are expanded.

## Templates

Each template below is preceded by a `<!-- TEMPLATE: <relative-path> -->` marker. The portable scaffolder greps for those markers and writes the fenced block contents (without the fence lines) to the indicated path inside the new skill directory.

### SKILL.md

<!-- TEMPLATE: SKILL.md -->
```markdown
---
name: ${SKILL_NAME}
description: ${SKILL_DESCRIPTION}
license: ${LICENSE}
compatibility: ${COMPATIBILITY}
metadata:
  autopoietic_version: "${AUTOPOIETIC_VERSION}"
  mission_hash: "${MISSION_HASH}"
  created_at: "${CREATED_AT}"
  scaffolded_by: autopoietic-builder
allowed-tools: ${ALLOWED_TOOLS}
---

# ${SKILL_TITLE}

## Mission

${MISSION_DOMAIN}

Full mission boundary: see [mission.md](mission.md). Mission is authoritative; never expand scope without a human edit to that file.

## Capabilities

| Intent | File | Action class | Confidence |
|--------|------|--------------|------------|
| _(none yet — capabilities are added on demand via the growth protocol)_ | | | |

The full registry lives at [capabilities/INDEX.md](capabilities/INDEX.md). Load only the capability file for the matched intent — never load the whole directory.

## When the requested intent is not in the table above

1. Read [mission.md](mission.md). Is the request inside the in-scope shapes and not in the out-of-scope list?
2. **In scope:** follow [references/growth-protocol.md](references/growth-protocol.md). Snapshot state, dispatch the learner, present the draft for confirmation, apply, resume.
3. **Out of scope:** refuse. Suggest a different skill or a human. Log to `learned/${CREATED_AT_DATE}-refused.md`.

**REQUIRED PROTOCOL:** When the intent is missing from the capability table but inside mission scope, follow `references/growth-protocol.md` exactly. Do not improvise a learning flow.

## Cache

Stable factual data (API endpoints, schemas, command references) lives in [cache/INDEX.md](cache/INDEX.md). Always check the cache index before any web fetch. Cache entries declare `last_verified` and `ttl_days`; if expired, the growth protocol triggers a re-fetch instead of trusting the stale value.

## Provenance

Every learning event is logged in `learned/<date>-<capability>.md` with cited URLs, content hashes, verification output, and confidence. See [references/anti-poisoning.md](references/anti-poisoning.md) for the schema and source-tier rules.

## Resume / crash recovery

In-flight requests are journaled in `.state/journal.ndjson` and `.state/<request-id>.md`. On any new invocation, the skill checks the journal for non-`DONE` entries and offers to resume. See [references/resume-state.md](references/resume-state.md).
```

### AGENTS.md

<!-- TEMPLATE: AGENTS.md -->
```markdown
# ${SKILL_TITLE}

This is an [agentskills.io](https://agentskills.io/specification)-compliant skill bundle. Cross-harness entry point.

The full instructions live in [SKILL.md](SKILL.md). Mission boundaries live in [mission.md](mission.md). Read those first.
```

### mission.md

<!-- TEMPLATE: mission.md -->
```markdown
# Mission

## Domain

${MISSION_DOMAIN}

## In scope

${MISSION_IN_SCOPE}

## Out of scope

${MISSION_OUT_OF_SCOPE}

## Action classes

| Class | Definition | Default policy |
|-------|------------|----------------|
| read  | No state change in the target system | autonomous after first-time confirm |
| write | Creates / modifies state, recoverable | autonomous after first-time confirm + sandbox-verify |
| destructive | Deletes / overwrites / publishes irreversibly | confirm every call until proven on N successful runs |

Per-skill overrides to the default policy go in this section. Mission is the only place an override may live.
```

### .gitignore

<!-- TEMPLATE: .gitignore -->
```
# Transient runtime state — never committed
.state/

# OS / editor noise
.DS_Store
*.swp
```

### capabilities/INDEX.md

<!-- TEMPLATE: capabilities/INDEX.md -->
```markdown
# Capability Index

Each row maps an **intent** the skill can satisfy to the **file** that contains the how-to and cached facts for that capability. The growth protocol appends a row when a new capability is accepted; rows are never silently rewritten.

| Intent | File | Action class | Confidence | Depends on | Last verified | Notes |
|--------|------|--------------|------------|------------|---------------|-------|

## Confidence states

- `tentative` — capability has been drafted and dry-run-verified, but not yet used in production. Skill warns on each invocation.
- `verified` — at least one successful real-world call has completed. Default state after first successful use.
- `deprecated` — superseded or no longer valid; soft-deleted by setting this flag.

## Conflict resolution

Two rows may share the same intent only if exactly one is `verified` and the other is `deprecated`. Otherwise, treat as a registry error and halt with a message to the user.
```

### cache/INDEX.md

<!-- TEMPLATE: cache/INDEX.md -->
```markdown
# Cache Index

Stable factual data the skill has cached locally to avoid repeated web fetches. Each row points to a file with structured content (tables, lists, schemas — no narrative).

| Topic | File | Last verified | TTL (days) | Source tier |
|-------|------|---------------|------------|-------------|

## Staleness rules

The growth protocol checks `last_verified + ttl_days` against today's date before reuse. If expired, the entry is refetched (with a fresh source-tier check) before being used. Re-fetch is logged in `learned/<date>-cache-refresh-<topic>.md`.
```

### learned/README.md

<!-- TEMPLATE: learned/README.md -->
```markdown
# Provenance Log

Append-only record of every learning event this skill has performed. One file per event, named `<YYYY-MM-DD>-<capability>.md` (or `-refused.md` / `-rejected.md`).

Each entry follows the schema defined in [`../references/anti-poisoning.md`](../references/anti-poisoning.md): YAML frontmatter with capability, date, action class, confidence, sources (URL + sha256 + tier), and verification output; followed by a freeform summary.

This directory is the audit trail. Do not delete entries. To retract a capability, mark its row in `capabilities/INDEX.md` as `deprecated` and add a new entry here explaining the retraction.
```

### tests/baseline/README.md

<!-- TEMPLATE: tests/baseline/README.md -->
```markdown
# Baseline Tests

Pressure scenarios that an agent **fails** when this skill is *not* present. These are the RED phase of TDD-for-skills: they document the bad behavior the skill exists to prevent.

Each test is a markdown file named `<NNN>-<short-name>.md` containing:

- **Setup:** what context the agent has
- **Prompt:** the exact user message to send to a baseline (no-skill) subagent
- **Expected failure:** the rationalization or wrong action the agent will produce
- **Why it fails:** the missing piece this skill teaches

Run with the test runner described in `../../README.md`. New capabilities should each have a matching baseline test.
```

### tests/growth/README.md

<!-- TEMPLATE: tests/growth/README.md -->
```markdown
# Growth Tests

Scenarios that exercise the self-mutation flow end-to-end. Each test is a markdown file containing:

- **Initial state:** what capabilities and cache entries exist before the test
- **Prompt:** the in-mission request the skill currently cannot satisfy
- **Expected flow:** which growth phases must be observed (DISPATCH → AWAIT → APPLY → RESUME)
- **Acceptance criteria:** what must be true at the end (new capability file, INDEX row, learned entry, original task completed)

A growth test passes if the skill performs the full cycle without breaking the mission boundary or skipping verification.
```

### .state/.gitkeep

<!-- TEMPLATE: .state/.gitkeep -->
```
# placeholder; .state/ is gitignored — this file exists only so the directory is created at scaffold time
```

## Files copied (not templated) from this plugin

The scaffolder copies these four files from the meta-skill into the generated skill's `references/` directory, byte-for-byte, with no substitution:

- `references/growth-protocol.md`
- `references/anti-poisoning.md`
- `references/verification-recipes.md`
- `references/resume-state.md`

Source location: `<plugin-root>/skills/autopoietic-builder/references/`. The scaffolder must resolve plugin-root from the script's own location (e.g., the shell scaffolder uses `dirname "$0"/.. ` to find it).

After scaffolding, the resulting skill must pass:

```bash
skills-ref validate <target-dir>/<skill-name>
```

(See https://github.com/agentskills/agentskills/tree/main/skills-ref for the validator.)
