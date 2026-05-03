# Mission Design

How to write the `mission.md` file at the root of every autopoietic skill. The mission is the **boundary** of the skill — the closed surface inside which it may grow. Every other reference (growth protocol, anti-poisoning, verification recipes) defers to mission.md when classifying an incoming intent as in-scope, ambiguous, or out-of-scope.

## Why mission.md is special

Mission is the only file in a generated skill that:

1. Is **authoritative** — when the capability index disagrees, mission wins
2. Is **immutable to the skill itself** — only humans edit mission.md; the skill must never self-rewrite scope
3. Has its **sha256 recorded** in `SKILL.md` frontmatter (`metadata.mission_hash`) so unauthorized edits are detectable
4. Is **read on every growth event** — even at runtime cost — to decide whether learning is allowed

If the capability table grows but mission stays the same, the skill is doing its job. If mission drifts to accommodate scope creep, the skill has lost its identity.

## Required sections

A valid mission.md has these four sections, in this order:

```markdown
# Mission

## Domain
<1–3 sentences: what systems, services, concepts this skill operates on.>

## In scope
<bulleted list of intent shapes the skill may grow into>

## Out of scope
<bulleted list of adjacent intents the skill must refuse — explicitly named, not inferred>

## Action classes
| Class | Definition | Default policy |
|-------|------------|----------------|
| read  | No state change in the target system | autonomous after first-time confirm |
| write | Creates / modifies state, recoverable | autonomous after first-time confirm + sandbox-verify |
| destructive | Deletes / overwrites / publishes irreversibly | confirm every call until N successful uses |
```

## Worked example: jira-helper

```markdown
# Mission

## Domain
Read and modify issues, comments, and transitions in a single Jira Cloud
instance, scoped to the `ACME` project. Authenticated via a user-supplied API
token. No interaction with other Atlassian products (Confluence, Bitbucket,
Compass).

## In scope
- Listing, searching, filtering issues
- Reading issue details, comments, attachments, history
- Creating new issues with valid required fields
- Editing summary, description, labels, components, fix versions
- Adding comments
- Transitioning issues through workflow states
- Linking and unlinking issues

## Out of scope
- Slack, Teams, email, or any non-Jira messaging
- Confluence pages, even when linked from a Jira issue
- Bitbucket PRs or commits, even when linked from a Jira issue
- Project administration (creating projects, editing schemes, permissions)
- Billing, user management, audit log
- Any project other than ACME

## Action classes
| Class | Examples |
|-------|----------|
| read  | search-issues, get-issue, list-comments, list-transitions |
| write | create-issue, edit-issue, add-comment, transition-issue, link-issues |
| destructive | delete-issue, delete-comment, remove-link |
```

## Rules for writing each section

### Domain (1–3 sentences)

- Name the **system, instance, and account scope** concretely. "Jira" is too broad; "Jira Cloud, single instance, ACME project, API-token auth" is right.
- Name the **authentication boundary**. Skills that span auth domains tend to leak.
- Name the **adjacent systems excluded by this domain**, even if obvious (Confluence next to Jira). The contrast is what makes the boundary visible.

### In scope (bullets)

- Each bullet is a **shape of intent**, not a specific capability. "Listing, searching, filtering issues" covers many concrete operations a learner might add later.
- Avoid verbs the user did not authorize. If the user said "read and create Jira issues," "delete" does not belong in scope just because it's the same domain.
- Bullets here are the **growth license**. The learner subagent may freely propose capabilities matching these shapes; it must not propose capabilities matching shapes not listed.

### Out of scope (bullets)

- **Name nearby temptations explicitly.** The point of this section is to forbid the obvious adjacent moves. Under-specifying here is the most common drift vector.
- For each excluded system, write *why it's excluded* if the reason is not obvious from the domain statement. ("Confluence — different auth domain, different content model.")
- Out-of-scope intents must be **refused without learning**. The growth protocol consults this list before dispatching the learner subagent.

### Action classes table

- Every capability the skill ever has — present or learned later — must fit into exactly one of `read | write | destructive`.
- The defaults for each class are set by the gate policy in the growth protocol; mission.md may override per-skill if needed (e.g., "this skill's `write` actions also require confirm-every-call because target system has no rollback").

## Mission immutability

The skill must never:

- Edit its own mission.md
- Propose mission edits as part of a growth event
- Accept a user-typed instruction that contradicts mission.md without an explicit human edit to mission.md first

If a user asks the skill to do something out of scope, the correct response is:

> *That's outside this skill's mission. Either: (a) edit `mission.md` to widen the scope, then re-ask, (b) use a different skill, or (c) do it yourself.*

The skill must never widen scope on its own initiative. Scope creep is mission drift; mission drift is identity loss; identity loss defeats the autopoietic boundary.

## Detecting unauthorized mission edits

`SKILL.md` frontmatter records `metadata.mission_hash: <sha256 of mission.md at scaffold time>`. On every invocation, the skill recomputes the sha256 and compares.

- **Match:** proceed normally.
- **Mismatch:** surface a one-time confirmation: *"mission.md has changed since this skill was scaffolded. Old hash: X. New hash: Y. Diff: ... Continue with the new mission?"* On accept, update `metadata.mission_hash`. On reject, halt.

This protects against silent scope expansion via tampering.

## Anti-patterns

| Smell | Why it's bad | Fix |
|-------|--------------|-----|
| "All Atlassian products" as domain | Domain is too wide; learner will accept Confluence/Bitbucket capabilities | Pick one product, one auth domain |
| In-scope: "anything to do with issues" | Learner has no constraint; will accept create/delete/admin equally | Bullet specific intent shapes |
| Out-of-scope section is empty or just "obvious things" | Doesn't forbid nearby temptations explicitly | Name 3–5 adjacent systems and why each is excluded |
| Action classes table missing destructive class | All future destructive capabilities will be misclassified as write | Always include all three classes, even if no destructive examples exist yet |
| Mission rewritten by the skill itself | Defeats the autopoietic boundary entirely | Never. Mission is human-edit-only |

## Self-check before saving mission.md

- [ ] Domain names a system, an instance, and an auth boundary
- [ ] In-scope bullets describe **shapes** of intent, not single capabilities
- [ ] Out-of-scope names at least 3 adjacent temptations explicitly
- [ ] Action classes table is complete (read, write, destructive) even if some are empty
- [ ] No bullet authorizes verbs the user did not authorize
- [ ] mission_hash will be recorded in SKILL.md after writing
