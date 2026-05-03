# Anti-Poisoning

Rules for what counts as a trustworthy source when the learner subagent acquires a new capability, and the schema for recording provenance so a future audit can re-verify.

The threat model: the open web is full of incorrect, outdated, or adversarial content. A skill that learns from low-quality content **caches that content into its own files**, which a less capable model will then trust on later runs. We block that by (1) preferring authoritative sources at learning time, (2) recording every URL with a content hash so drift is detectable later, and (3) requiring human confirmation before any new capability is committed.

## Source-tier preference order

The learner ranks candidate sources into five tiers and prefers higher tiers monotonically. Lower tiers are usable only if no higher-tier source is available, and only with explicit acknowledgment.

| Tier | Examples | Use for |
|------|----------|---------|
| 1 — Official docs | `docs.atlassian.com`, `docs.stripe.com`, `cloud.google.com/docs` | Default for any capability |
| 2 — API specs | OpenAPI / Swagger / GraphQL schema files published by the vendor | Default for write/destructive capabilities |
| 3 — Vendor SDKs | Vendor-published client libraries (source code on GitHub) | Acceptable for read; flag for write |
| 4 — GitHub source | The vendor's own server-side or open-source repo | Acceptable for read; flag for write/destructive |
| 5 — Community | Stack Overflow, blogs, tutorials, forum posts | **Never alone for write or destructive.** Allowed only as supplementary context to a tier 1–3 primary source for read capabilities |

The learner must include at least one tier-1 or tier-2 source for any `write` capability and **must** include tier-1 or tier-2 for any `destructive` capability.

## Source verification at fetch time

For every URL the learner fetches:

1. Record the full URL (including version/path; never just the domain)
2. Record `fetched_at` as ISO-8601 UTC
3. Compute and record the **sha256 of the fetched content** (the raw HTML or JSON, not a summary)
4. Assign a tier. If the tier is unclear, drop the source and find another. Do not guess.

Truncated or summarized content does not get hashed. The hash is on the byte stream the learner actually used to derive the capability — anything less is unverifiable.

## Provenance entry schema

Every learning event writes one file at `learned/<YYYY-MM-DD>-<capability>.md`. Schema:

```markdown
---
capability: <name matching the row in capabilities/INDEX.md>
date: <YYYY-MM-DD>
event: learned | refused | rejected | cache-refresh
action_class: read | write | destructive
confidence: tentative | verified
sources:
  - url: https://docs.example.com/api/v1/issues/create
    fetched_at: 2026-05-03T18:42:11Z
    sha256: 3c9b1d8f0e6a4c2b7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c
    tier: 1
    excerpted_lines: "L120-L168"   # which lines of the source the capability draws from; aids re-audit
  - url: ...
verification:
  method: sandbox-call | dry-run | describe-only
  command: |
    <the exact command/request used>
  output: |
    <truncated to ≤30 lines; full output in capabilities/<cap>.md if needed>
  outcome: pass | fail | partial
risks:
  - <free-text risks the learner flagged: irreversibility, rate limits, auth scope, etc.>
---

## Summary

<2–4 sentences: what was learned, the smallest concrete fact that justifies the capability>

## Sources excerpt

<verbatim quote from the highest-tier source — the specific paragraph(s) the capability is built on. This is what re-auditors compare against future fetches of the same URL.>
```

## Refused / rejected / cache-refresh entries

The same schema is used for non-learning events, with `event:` set accordingly:

- `event: refused` — the request was out-of-scope per `mission.md`. Sources, verification, and risks are omitted; only the request and the matching out-of-scope bullet are recorded.
- `event: rejected` — the user declined the proposed capability at the confirmation gate. The full draft is preserved; sources and verification are recorded as the learner submitted them.
- `event: cache-refresh` — an existing `cache/<topic>.md` exceeded its TTL and was re-fetched. Sources record the new fetch; the diff against the previous content's sha256 goes in the summary.

## Re-audit procedure

A skill (or a human) can re-verify any past learning event:

1. Read the `learned/<entry>.md` file
2. Re-fetch each `sources[].url`
3. Compute fresh sha256 of each
4. Compare:
   - **All hashes match:** the cached knowledge is still valid against current sources. Bump `verified_at` in `capabilities/INDEX.md`.
   - **Hashes differ:** content has drifted. Flag the capability `confidence: tentative` until human review. Optionally, run the learner again to refresh the capability.

Re-audit is what makes "model poisoning" recoverable: even if a learner once ingested a bad source, the hash record makes the divergence visible later.

## Hard rules

- **No tier-5 source alone justifies a write or destructive capability.** Ever. The learner refuses to draft.
- **No undated source.** If a fetched page has no version/date and the URL is not version-pinned, the learner must cite a version-pinned alternative or refuse.
- **No source without a recorded hash.** If the harness does not allow content-hash computation, log that fact in `risks` and downgrade `confidence` to `tentative` permanently for that capability.
- **No silent re-summary of cached knowledge.** When the learner builds a capability file from an existing `cache/<topic>.md`, it cites that cache file as a source (with its current sha256) rather than re-fetching.

## Failure modes and required behavior

| Failure | Required behavior |
|---------|-------------------|
| Vendor docs (tier 1) are paywalled or login-walled | Fall back to tier 2 (API spec). If unavailable, refuse to draft and report to the user |
| Multiple tier-1 sources contradict each other | Surface the contradiction to the user; do not pick a winner silently |
| The fetched content is shorter than 200 bytes | Treat as fetch failure; do not hash; refuse to use as a source |
| The URL redirects to a different host | Record both URLs and both hashes; treat tier as the lower of the two |
| Same URL fetched twice produces different hashes within minutes | Page is dynamic / personalized; flag in `risks` and prefer a static alternative |
