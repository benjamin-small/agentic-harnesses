# Tests

Pressure scenarios for the autopoietic-builder meta-skill, following the TDD-for-skills pattern (RED-GREEN-REFACTOR) from `superpowers:writing-skills`. Each scenario in `baseline/` describes a failure mode an agent without this skill exhibits; the matching scenario in `with-skill/` describes the behavior the skill must produce.

## How to run

These are **subagent pressure scenarios**, not unit tests. Run each one by:

1. Spawning a subagent (e.g., via Claude Code's `Agent` tool, Codex's equivalent, etc.)
2. Giving it the **Setup**, **Files**, and **Prompt** sections from the test file
3. **Baseline runs:** the subagent has no access to the autopoietic-builder skill or any of its references. Document what it does.
4. **With-skill runs:** the subagent has the autopoietic-builder skill loaded. Verify it follows the **Expected behavior** section.

A test passes when:

- Baseline run reproduces the **Documented failure** (RED)
- With-skill run produces the **Expected behavior** (GREEN)

A test fails (and the skill needs refactoring) when:

- Baseline run does NOT exhibit the documented failure → the test is no longer pressure-bearing; revise it
- With-skill run does NOT produce the expected behavior → the skill has a gap or the description has hit the CSO trap

## Iron Law

Per `superpowers:writing-skills`: no skill change without a failing test first. Adding a new capability to the autopoietic flow means adding a baseline + with-skill pair that exercises the new capability before the change ships.

## Test inventory

### Baseline (must FAIL without the skill)
- `001-no-mission-boundary.md` — agent accepts an out-of-scope request and improvises
- `002-context-pollution.md` — agent loads everything in `capabilities/` instead of the matched file
- `003-no-provenance.md` — agent learns from a tier-5 blog and ships the capability silently
- `004-no-resume.md` — agent forgets the original task after pivoting to learn

### With-skill (must PASS with the skill)
- `001-mission-refusal.md` — agent refuses out-of-scope cleanly, logs to `learned/`
- `002-progressive-disclosure.md` — agent loads only the matched capability file
- `003-growth-end-to-end.md` — agent dispatches learner, surfaces confirmation, applies, resumes
- `004-crash-recovery.md` — orphan capability files are detected and removed
