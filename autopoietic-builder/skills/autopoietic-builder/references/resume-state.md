# Resume State

The state machine and on-disk format for journaling in-flight requests so that:

1. A growth event interrupted by a session crash can be **resumed** in a later session
2. A partial APPLY (capability file written but INDEX not updated) can be **detected** and rolled back
3. Concurrent or repeated invocations cannot accidentally clobber each other's work

The state lives entirely in `.state/`, which is gitignored. Knowledge ships with the skill; state never does.

## Files

```
.state/
├── journal.ndjson                  # append-only stream of phase transitions
├── <request-id>.md                 # human-readable snapshot per active request
└── completed/
    └── <request-id>.md             # archived snapshots (still gitignored)
```

### `journal.ndjson`

One JSON object per line, append-only. Every state transition writes one line **before** the action it describes runs (so a crash mid-action still leaves a record of intent). Schema:

```json
{
  "ts": "2026-05-03T18:42:11.123Z",
  "request_id": "req-1714766531123-a4f9",
  "phase": "RECEIVED",
  "intent": "create-issue",
  "details": { "...optional phase-specific data..." }
}
```

`phase` is one of:

```
RECEIVED              first contact with a request
HIT                   capability matched in INDEX; about to EXECUTE
MISS                  no match; about to MISSION_CHECK
OUT_OF_SCOPE          mission rejected the request
SNAPSHOT              wrote .state/<id>.md; entering learning
DISPATCHED            dispatched the learner subagent
LEARNER_RETURNED      learner returned drafts; about to AWAIT_CONFIRMATION
ACCEPTED              user accepted the draft; about to APPLY
REJECTED              user rejected the draft
APPLY_COMPLETE        capability and INDEX writes finished
RESUME_START          loaded the snapshot; about to execute the original request
DONE                  request complete (with outcome field)
ORPHAN_REMOVED        crash-recovery deleted an orphan capability file
```

`details` is optional and phase-specific. For `DONE`, it always includes `outcome: success | rejected | refused | resumed-but-failed`.

### `<request-id>.md`

Markdown with YAML frontmatter. Written at SNAPSHOT and updated only at terminal phases. Schema:

```markdown
---
request_id: req-1714766531123-a4f9
phase: SNAPSHOT
created_at: 2026-05-03T18:42:11Z
intent: create-issue
mission_hash: 3c9b1d8f0e6a4c2b...
---

## Original request

<verbatim user message>

## Context at snapshot time

<files mentioned, decisions already made, anything the resumer needs to pick up cleanly>

## Drafts (added at LEARNER_RETURNED)

- proposed-capability: capabilities/create-issue.md
- proposed-cache-deltas: [cache/api-endpoints.md]
- proposed-provenance: learned/2026-05-03-create-issue.md

## Resolution (added at DONE)

<filled in only when terminal>
```

The single snapshot file is the **only** place the original request and resume context lives. Do not duplicate it into the journal — the journal is a stream of decisions, the snapshot is the resumable workspace.

## Request id format

`req-<unix-millis>-<random4>` where random4 is 4 lowercase hex chars. Sufficient for single-user; not designed for multi-instance concurrency (deferred to v2).

## Crash recovery on startup

Run this **before** processing any new user message:

1. Read `journal.ndjson`. Group entries by `request_id`. Find the latest entry per group.
2. For each group whose latest is **not** terminal (`DONE`, `OUT_OF_SCOPE`, `REJECTED`):
   - Read `.state/<id>.md` if it exists.
   - If latest is `RECEIVED` or `MISS` → discard (no work was in progress). Append `phase: DONE, outcome: discarded-on-recovery`.
   - If latest is `SNAPSHOT` or `DISPATCHED` → the learner never returned (crashed mid-fetch). Discard the snapshot. Append `phase: DONE, outcome: discarded-on-recovery`.
   - If latest is `LEARNER_RETURNED` → drafts were never confirmed. Discard. Append `phase: DONE, outcome: discarded-on-recovery`.
   - If latest is `ACCEPTED` but no `APPLY_COMPLETE` → APPLY was interrupted. Run **orphan check** (below) then surface to user: *"A previous run was applying capability X but didn't finish. I've cleaned up partial files. Want to retry the original request: '...'?"*
   - If latest is `APPLY_COMPLETE` but no `RESUME_START` or `DONE` → APPLY succeeded, RESUME never ran. Surface: *"A previous run added capability X but didn't complete the original request. Resume now?"*
3. **Orphan check** (always run, regardless of any in-flight requests):
   - List `capabilities/*.md`. For each filename `X.md`, look for a matching row in `capabilities/INDEX.md`.
   - Any file with no row is an **orphan** from a partial APPLY. Delete the file. Append `phase: ORPHAN_REMOVED, request_id: <unknown-or-from-journal>` with the filename in `details`.
   - Same check on `cache/*.md` against `cache/INDEX.md`.

After crash recovery completes, normal processing of the new request begins.

## Why journal-before-action

The journal entry for `phase X` is written *before* the action `X` describes runs. If the action crashes, the journal still records the intent — and crash recovery can decide what to do.

The opposite (journal-after-action) would mean a crash in the action leaves no record, which is exactly the case we cannot recover from.

The cost: a journal line that describes work that never finished. Crash recovery handles those by treating any non-terminal phase as recoverable-or-discardable per the rules above.

## Atomic commit point

Within `APPLY`, the writes happen in this exact order:

1. `cache/<topic>.md` files (new content)
2. `capabilities/<cap>.md`
3. `learned/<date>-<cap>.md`
4. `cache/INDEX.md` row (if cache entries were added)
5. **`capabilities/INDEX.md` row** ← this is the atomic commit point
6. `SKILL.md` capability table regeneration

Step 5 is what crash recovery looks at when deciding whether a partial APPLY succeeded. Anything from step 1–4 that exists without the corresponding INDEX row is an orphan.

Step 6 is idempotent — regenerating from INDEX always produces the same table, so a crash between 5 and 6 is recoverable by simply re-running step 6 on next startup.

## Concurrency notes (deferred to v2)

The current design assumes a single-user, single-session model. For multi-session work:

- The journal is append-only and tolerates concurrent writes only on filesystems that guarantee atomic single-line append (most do, but not all)
- `<request-id>.md` files are per-request and do not collide
- `capabilities/INDEX.md` and `cache/INDEX.md` are the contention points: simultaneous APPLY events from two sessions can produce duplicate rows or interleaved row writes

A robust v2 fix is a `.lock` file on each INDEX during APPLY, with a stale-lock timeout. Out of scope for v1.
