# With-skill 004 — Crash recovery removes orphan capability files

## Setup

Scaffold a fresh `jira-helper`. Manually simulate a crashed APPLY by:

1. Writing `capabilities/create-issue.md` with realistic content
2. Writing `learned/<today>-create-issue.md` per the anti-poisoning schema
3. **Not** adding the matching row to `capabilities/INDEX.md`
4. Appending to `.state/journal.ndjson`:
   ```json
   {"ts":"<earlier>","request_id":"req-test-orphan","phase":"ACCEPTED","intent":"create-issue"}
   ```
   (note: no `APPLY_COMPLETE`, no `DONE`)

The state simulates: a previous session accepted the draft, started writing files, but crashed before the INDEX row landed.

## Prompt

> List the open issues in project ACME.

(Any new request — the crash recovery procedure runs on startup before processing.)

## Expected behavior

Before processing the new request, the subagent must run **crash recovery** (per `references/resume-state.md`):

1. Read `.state/journal.ndjson`. Find the open `req-test-orphan` group at `phase: ACCEPTED` with no terminal entry.
2. Run **orphan check**: scan `capabilities/*.md`, find `create-issue.md` with no row in `capabilities/INDEX.md`. Delete the orphan file.
3. Append `phase: ORPHAN_REMOVED` to journal with the deleted filename in `details`.
4. Append `phase: DONE, outcome: discarded-on-recovery` for `req-test-orphan`.
5. Surface to the user **once** at the start of the response: *"Crash recovery: removed an orphan capability file (create-issue.md) from a previous incomplete run. Original request 'create-issue' was not completed; you can re-issue it if you still want it."*
6. Then continue with the new request (`list-issues`).

## Acceptance criteria

After the run:

- [ ] `capabilities/create-issue.md` no longer exists
- [ ] `learned/<today>-create-issue.md` is preserved (the audit trail outlives the orphan)
- [ ] `capabilities/INDEX.md` is unchanged (no spurious rows)
- [ ] `.state/journal.ndjson` has new `ORPHAN_REMOVED` and `DONE`/`discarded-on-recovery` entries
- [ ] The original `list-issues` request was completed correctly
- [ ] The user was informed about the recovery exactly once

## Pass criterion (GREEN)

3 with-skill runs. All 3 must satisfy every acceptance criterion. A run that misses the orphan, deletes it silently, or fails to complete the new request is a fail.
