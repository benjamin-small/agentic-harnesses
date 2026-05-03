# Verification Recipes

How the learner subagent demonstrates that a drafted capability actually works *before* it is presented at the confirmation gate. Recipes vary by action class because the cost of a bad call varies wildly: a misread is cheap, a botched delete is unrecoverable.

The verification output is part of every `learned/<date>-<cap>.md` entry and part of every confirmation prompt the user sees. A capability with weak verification cannot be confidently auto-applied on reuse — its `confidence` stays `tentative` until a real call succeeds.

## Recipe by action class

### `read` — sample call

Read capabilities are verified by **actually executing a representative call** against the live system, with safe parameters.

Procedure:

1. Pick the smallest representative call (e.g., list with `limit=1`, get a known-public resource)
2. Execute it with the configured auth
3. Capture the response status, response shape (top-level keys), and a 5–10 line excerpt of the body
4. Assert the response shape matches what the capability description claims
5. Record method=`sandbox-call`, the exact command, the truncated output, and `outcome=pass|fail`

Example:

```yaml
verification:
  method: sandbox-call
  command: |
    curl -s -H "Authorization: Bearer $TOKEN" \
      "https://acme.atlassian.net/rest/api/3/search?jql=project=ACME&maxResults=1"
  output: |
    HTTP/200
    {"total": 1247, "issues": [{"id": "10001", "key": "ACME-1", "fields": {...}}]}
  outcome: pass
```

If the call fails (auth error, 4xx, 5xx), the learner does **not** ship the capability. It returns a failed verification to the parent, which surfaces the failure to the user instead of a confirmation prompt. The user can fix auth and retry, or abandon.

### `write` — dry-run / preview

Write capabilities create or modify state. Verification must demonstrate the call succeeds **without** committing real changes.

Procedure (in priority order):

1. **Dry-run flag**, if the API supports it (e.g., `POST .../validate`, `?dryRun=true`, OpenAPI `examples`). Use it.
2. **Sandbox / preview environment**, if the vendor publishes one (Stripe test mode, Atlassian sandbox instances, etc.). Use it with a clearly-marked test resource.
3. **Reversible smoke test:** create a resource, immediately read it back to confirm shape, immediately delete it. Acceptable only if the create + delete sequence is itself in scope per `mission.md`. Mark in `risks` that the verification mutated state.
4. **Schema validation:** if no dry-run is available, validate the request body against the API's published schema and execute *only* a 1-byte HEAD or OPTIONS call to confirm the endpoint exists. Mark `outcome: partial` and `confidence: tentative`.

Always record:

```yaml
verification:
  method: dry-run
  command: |
    POST /rest/api/3/issue?dryRun=true
    Body: {"fields": {"project": {"key": "ACME"}, "summary": "verify-test", ...}}
  output: |
    HTTP/200
    {"valid": true, "preview": {"key": "ACME-NEXT", ...}}
  outcome: pass
```

If none of the four options is available, the learner refuses to draft a `write` capability and reports the gap to the user. The user may explicitly opt in to a tier-3 confidence draft.

### `destructive` — describe-only

Destructive capabilities (delete, overwrite, publish, irreversible-transition) are **never** executed during verification. The cost of a wrong destructive call exceeds the value of the verification.

Procedure:

1. Locate and quote the exact API contract (request shape, parameters, irreversibility note)
2. Identify the **safety preconditions** the capability must check before calling: target exists, target is in expected state, user has authority, target is not protected (e.g., default branches, primary records)
3. Identify the **post-conditions** the capability must verify after calling (typically a 404 or read returning the deleted state) and how to surface a partial failure
4. Identify the **rollback story**, if any. If none exists, that is recorded explicitly in `risks`.

Record:

```yaml
verification:
  method: describe-only
  command: |
    DELETE /rest/api/3/issue/{issueIdOrKey}
  output: |
    Per docs (tier 1, sha256 …): returns 204 on success, 404 if missing, 403 if user lacks permission.
    Irreversible: deleted issues cannot be restored via API.
    Preconditions: target exists, current user has 'Delete Issues' permission, issue is not in a closed sprint owned by another user.
    Postconditions: subsequent GET on same key returns 404.
    Rollback: none.
  outcome: pass   # "pass" here means description is complete and self-consistent, not that a call ran.
```

`destructive` capabilities are always `confidence: tentative` until they have **N successful real-world uses** (default N=3, set per skill in `mission.md`). Until then, the confirmation gate fires on every call, not just first use.

## Cache verification

When the learner caches a stable factual artifact (an API endpoint list, a schema, a command reference), the cache file is verified the same way as a `read` capability: a sample call against one item from the cache must succeed.

Cache TTL is set in the entry's frontmatter (`ttl_days`). On staleness, the growth protocol re-runs cache verification before reuse — a bumped sha256 is fine; a failed sample call invalidates the entry and forces a re-fetch.

Cache files **must not** mix structured data and prose narrative. Tables, lists, fenced examples — never paragraphs. Narrative belongs in `learned/`, not `cache/`.

## What `outcome: fail` means in each class

| Class | `pass` | `partial` | `fail` |
|-------|--------|-----------|--------|
| read | sample call returned expected shape | sample call returned but shape differs from spec | call returned error or refused auth |
| write | dry-run validated | only schema validation, no live call | dry-run rejected, smoke test failed, or no verification possible |
| destructive | description complete and self-consistent | description is missing rollback or postconditions | description is missing preconditions or contradicts API spec |

A `fail` always blocks the capability. The learner returns the failure; the user sees the failure (not a confirmation prompt) and decides what to do.

A `partial` is presented at the confirmation gate, with the gap called out. The user may accept (capability ships at `tentative` and stays there permanently until a stronger verification can be run) or reject.

## Things that are not verification

These are common rationalizations and do not count:

- "The docs say it works" — verification requires evidence beyond the same source the capability was learned from
- "I read the response schema" — schema reading is a precondition, not verification
- "The vendor's tutorial walks through this exact command" — tutorial walkthroughs are tier 5; not sufficient for write/destructive
- "I'd tested this skill before" — past sessions are not in the journal; verification must be reproducible from this session's evidence
- "It's idempotent so failure is safe" — idempotence is a property of the call, not of the verification; still must run
