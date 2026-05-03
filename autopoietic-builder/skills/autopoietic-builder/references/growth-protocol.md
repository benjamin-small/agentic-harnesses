# Growth Protocol

This file ships inside every autopoietic skill (copied from the meta-skill at scaffold time). It is the runtime instructions a skill follows when an in-mission request lands outside its current capability index. Generated skills reference this file by relative path (`references/growth-protocol.md`); the meta-skill is not consulted at runtime.

## When this protocol applies

Run this protocol exactly when **all** of the following are true:

1. A request has arrived
2. The matching intent is **not** in `capabilities/INDEX.md`
3. The intent **is** in `mission.md`'s in-scope list and **is not** in the out-of-scope list

If any of those is false:

- Intent matches a row in INDEX → load that capability file only, execute, done. Do not run this protocol.
- Intent is in mission's out-of-scope list → refuse. Log to `learned/<date>-refused.md`. Do not run this protocol.
- Intent is ambiguous (could plausibly match either list) → ask the user once. Do not learn until disambiguated.

## State machine

```
        RECEIVED
           │
           ▼
   CAPABILITY_LOOKUP
       │       │
   (HIT)    (MISS)
       │       │
   EXECUTE  MISSION_CHECK
       │       │       │
       │   (OUT)   (IN)
       │       │       │
       │   REFUSE  SNAPSHOT
       │       │       │
       │       │       ▼
       │       │   DISPATCH_LEARNER
       │       │       │
       │       │       ▼
       │       │   AWAIT_CONFIRMATION
       │       │       │       │
       │       │   (REJECT) (ACCEPT)
       │       │       │       │
       │       │   ABORT     APPLY
       │       │       │       │
       │       │       │       ▼
       │       │       │     RESUME
       │       │       │       │
       ▼       ▼       ▼       ▼
              DONE
```

Every transition is appended to `.state/journal.ndjson` *before* the action it describes runs. The journal is the source of truth for resume.

## Phase-by-phase

### 1. RECEIVED → CAPABILITY_LOOKUP

Generate a request id (e.g., `req-<unix-millis>-<rand4>`). Append:

```json
{"ts":"<iso8601>","request_id":"<id>","phase":"RECEIVED","intent":"<best-effort intent label>"}
```

Read `capabilities/INDEX.md`. Match the intent against the rows. Matching is by intent label, not by request text — extract the verb+object intent first.

### 2a. HIT → EXECUTE → DONE

Load **only** the file in the matched row. Do not read any other capability file. Do not read cache files unless that file says to.

Execute the request. On completion, append:

```json
{"ts":"<iso8601>","request_id":"<id>","phase":"DONE","outcome":"success"}
```

Stop. Do not continue this protocol.

### 2b. MISS → MISSION_CHECK

Read `mission.md`. Recompute its sha256 and compare with `metadata.mission_hash` in `SKILL.md`'s frontmatter.

- **Hash mismatch:** halt and surface the diff to the user. Do not learn against an unauthorized mission. After the user accepts the new mission, update `metadata.mission_hash` and continue.
- **Hash match:** classify the intent.

Classification rules:

- Matches an in-scope bullet **and** does not match any out-of-scope bullet → IN
- Matches any out-of-scope bullet → OUT (even if it also matches in-scope)
- Matches neither → ambiguous; ask the user once

### 3a. OUT → REFUSE → DONE

Write `learned/<YYYY-MM-DD>-refused-<short-intent>.md` with the request text, the matching out-of-scope bullet, and the timestamp.

Reply to the user: *"That's outside this skill's mission ('<bullet>'). To do it, either widen mission.md (and re-run), use a different skill, or do it manually."*

Append `DONE` to the journal with `outcome:"refused"`. Stop.

### 3b. IN → SNAPSHOT

Write `.state/<request-id>.md`:

```markdown
---
request_id: <id>
phase: SNAPSHOT
created_at: <iso8601>
intent: <intent label>
mission_hash: <current sha256>
---

## Original request

<verbatim user message>

## Context at snapshot time

<any conversation context the skill needs to resume — files mentioned, decisions already made, etc.>
```

Append journal entry with `phase:"SNAPSHOT"`. Now safe to enter the learning phase.

### 4. DISPATCH_LEARNER

Dispatch the learner subagent. The subagent's contract is defined in `agents/capability-learner.md` (in the meta-skill; generated skills do not need to host the subagent definition since dispatch happens through the harness). Pass it:

- The intent label
- `mission.md` content (so the learner knows scope)
- The relevant in-scope bullet (so the learner stays narrow)
- The action class to use (read | write | destructive — the learner picks based on the intent and mission's class table)
- Pointer to `references/anti-poisoning.md` (source-tier rules)
- Pointer to `references/verification-recipes.md` (how to verify per class)

The learner returns:

- A draft `capabilities/<cap>.md` (how-to + any cached facts it picked up)
- A draft cache delta (new entries for `cache/INDEX.md` and `cache/<topic>.md` files, if any stable facts were worth caching)
- A draft `learned/<YYYY-MM-DD>-<cap>.md` provenance entry (per anti-poisoning schema)
- The verification output (sandbox-call response, dry-run output, or describe-only summary)
- The proposed action class

Append journal entry with `phase:"LEARNER_RETURNED"`. Drafts are held in memory; nothing has been written to the canonical files yet.

### 5. AWAIT_CONFIRMATION (the gate — every new capability)

Present to the user, in a single message:

1. **Proposed capability:** name, action class, 1-line summary
2. **Sources cited:** URLs with their tier label (1=official-docs … 5=community)
3. **Verification:** the method used and the relevant excerpt of the output
4. **Risks:** anything the learner flagged (auth scope, irreversibility, rate limits)
5. **Question:** *"Add this capability and resume your original request? [yes / no / edit]"*

This confirmation gate runs **on every new capability**, regardless of action class. After acceptance, the capability is autonomous on reuse — but never on its first use.

If the user picks `edit`, accept their edits to the draft (typically a tighter description, a removed source, or a stricter action class) and re-present the updated draft. Do not loop on `edit` more than 3 times — if still not accepted, treat as `no`.

#### 5a. REJECT → ABORT → DONE

Write `learned/<YYYY-MM-DD>-rejected-<cap>.md` with the draft contents and the user's reason if given. Discard all draft files. Append `DONE` with `outcome:"rejected"`. Offer the user: continue without this capability (limited fallback) or end the request.

### 5b. ACCEPT → APPLY

Atomic-commit order is critical. The journal entry for `APPLY` is written **before** the writes; the writes happen in this exact order:

1. Write `cache/<topic>.md` files for any new cache entries
2. Write `capabilities/<cap>.md`
3. Write `learned/<YYYY-MM-DD>-<cap>.md`
4. Append the new row to `cache/INDEX.md` (if cache entries were added)
5. **Append the new row to `capabilities/INDEX.md` LAST** — this is the atomic commit point
6. Update `SKILL.md` capability table to mirror INDEX.md (regenerate the table from INDEX.md)

Append journal `phase:"APPLY_COMPLETE"`.

If a crash interrupts between steps 1 and 5, the partial state is recoverable: any `capabilities/<cap>.md` without a corresponding row in `INDEX.md` is an **orphan** and is deleted on the next run (see Crash recovery below).

### 6. RESUME → DONE

Read `.state/<request-id>.md`. Read the just-written `capabilities/<cap>.md`. Execute the original request as if the capability had been there from the start.

On success, the capability's confidence flips from `tentative` to `verified` (update the row in `capabilities/INDEX.md`). On failure, stay at `tentative` and surface the failure to the user; the capability remains usable but warns on each call until verified.

Move `.state/<request-id>.md` to `.state/completed/<request-id>.md` (still gitignored).

Append journal `phase:"DONE"` with `outcome:"success"` or `outcome:"resumed-but-failed"`.

## Confirm-first-time, autonomous-on-reuse

The gate at AWAIT_CONFIRMATION fires **only when the capability does not yet exist in INDEX.md**. Once a row is in INDEX:

- `read` capabilities → execute autonomously on every subsequent call
- `write` capabilities → execute autonomously on every subsequent call
- `destructive` capabilities → execute autonomously **after N successful uses** (default N=3), tracked in the row's metadata. While count < N, confirm before each call.

Mission may override these defaults per-skill (see Action classes section in `mission.md`).

## Crash recovery

On every skill invocation (before processing the new request), run this check:

1. Read `.state/journal.ndjson`. Group entries by `request_id`.
2. For each group whose latest entry is not `DONE` or `outcome:"refused"`/`"rejected"`:
   - If latest is `RECEIVED` or `SNAPSHOT` → safe to discard. Delete `.state/<id>.md`.
   - If latest is `LEARNER_RETURNED` → drafts were never applied; discard.
   - If latest is `APPLY_COMPLETE` but no `DONE` → APPLY succeeded but RESUME never ran. Offer the user: *"A previous run added capability X but didn't complete the original request: '<verbatim>'. Resume now?"*
   - **Orphan check:** scan `capabilities/*.md`. Any file whose name is not in `capabilities/INDEX.md` is an orphan from a partial APPLY. Delete it. Log the deletion in the journal as `phase:"ORPHAN_REMOVED"`.

Crash recovery never runs the learner. It only handles already-decided state.

## Anti-patterns

| Smell | Why it's bad | Correct behavior |
|-------|--------------|------------------|
| Skipping confirm because "the user clearly wants this" | Defeats anti-poisoning; first-time gate is the only review the cached knowledge gets | Always confirm new capabilities, even when obvious |
| Loading `capabilities/<other-cap>.md` while answering a different intent | Pollutes context, defeats progressive disclosure | Load only the file in the matched INDEX row |
| Editing `mission.md` during a growth event | Mission is human-edit-only; this is mission drift | Halt and ask the user to edit mission first |
| Writing INDEX.md before the capability file | Reader sees an entry pointing at a non-existent file → broken state | INDEX is the LAST write — it's the atomic commit |
| Re-fetching the web on every invocation | Defeats the cache; also burns tokens and risks poisoning | Check `cache/INDEX.md` first; only fetch if missing or expired |
| Marking new capability as `verified` immediately | The first real call hasn't happened yet | Always `tentative` until first successful call |
| Silently accepting a tier-5 (blog) source | Anti-poisoning forbids this for write/destructive | Surface to user; require explicit override or refuse |
