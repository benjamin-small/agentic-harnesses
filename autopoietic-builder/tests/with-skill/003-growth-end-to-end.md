# With-skill 003 — Growth end-to-end (the headline test)

## Setup

Scaffold a fresh `jira-helper`. Edit `mission.md` to put `create-issue` in the **in-scope** list. The `capabilities/INDEX.md` is empty.

```
jira-helper/
├── SKILL.md
├── mission.md            # in-scope includes "Creating new issues with valid required fields"
├── capabilities/
│   ├── INDEX.md          # empty rows
└── ...
```

## Prompt

> Create a new Jira issue in project ACME titled "Verify deploy succeeded" with description "Smoke check after release N+1."

## Expected behavior — full growth cycle

The subagent must execute the complete state machine from `references/growth-protocol.md`:

1. **CAPABILITY_LOOKUP:** read `capabilities/INDEX.md`, find no `create-issue` row → MISS
2. **MISSION_CHECK:** read `mission.md`, classify intent as IN (matches the "Creating new issues" bullet)
3. **SNAPSHOT:** write `.state/<request-id>.md` with the original request and the journal entry. Append `phase: SNAPSHOT` to journal.
4. **DISPATCH_LEARNER:** dispatch the `capability-learner` subagent. Pass mission, in-scope bullet, action class (`write`), pointers to anti-poisoning and verification recipes.
5. **LEARNER_RETURNED:** the learner returns drafts:
   - `capabilities/create-issue.md`
   - Optionally `cache/api-endpoints.md` if it cached the create-issue endpoint
   - `learned/<today>-create-issue.md` with at least one tier-1 source (URL + sha256) and a `dry-run` or `sandbox-call` verification with `outcome: pass`
6. **AWAIT_CONFIRMATION:** present to the user with: capability name, action class (`write`), source URLs and tiers, verification output excerpt, risks. Ask for accept / reject / edit.
7. **APPLY (on user accept):** write files in this exact order:
   1. `cache/api-endpoints.md` (if cache delta)
   2. `capabilities/create-issue.md`
   3. `learned/<today>-create-issue.md`
   4. `cache/INDEX.md` row
   5. `capabilities/INDEX.md` row (LAST — atomic commit)
   6. Regenerate the capability table in `SKILL.md`
8. **RESUME:** load `.state/<request-id>.md`, read the just-written `capabilities/create-issue.md`, execute the original request, return the new issue key/URL to the user
9. After successful real-world call, flip `confidence: tentative` → `verified` in `capabilities/INDEX.md`. Move `.state/<id>.md` to `.state/completed/<id>.md`. Append `phase: DONE, outcome: success` to journal.

## Acceptance criteria

After the run completes, verify on disk:

- [ ] `capabilities/INDEX.md` has a row for `create-issue` with `confidence: verified`
- [ ] `capabilities/create-issue.md` exists and contains the procedure (≤300 lines, structured)
- [ ] `learned/<today>-create-issue.md` exists with frontmatter listing all sources, hashes, tiers, and verification output
- [ ] At least one source has `tier: 1` or `tier: 2` (per anti-poisoning rules for `write`)
- [ ] `.state/journal.ndjson` shows the full sequence: `RECEIVED → SNAPSHOT → DISPATCHED → LEARNER_RETURNED → ACCEPTED → APPLY_COMPLETE → RESUME_START → DONE`
- [ ] `.state/<request-id>.md` is in `completed/`
- [ ] `SKILL.md` capability table includes the new row
- [ ] The original Jira issue was actually created in the live system (response key/URL present in the user-facing reply)
- [ ] Self-containment audit still passes: `grep -r 'autopoietic-builder:' jira-helper/` returns nothing

## Pass criterion (GREEN)

3 with-skill runs. All 3 must satisfy every acceptance criterion. A single missing acceptance criterion is a fail (the protocol exists to prevent exactly that gap).
