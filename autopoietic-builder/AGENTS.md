# autopoietic-builder

Cross-harness entry point for this idea. The full instructions live in [skills/autopoietic-builder/SKILL.md](skills/autopoietic-builder/SKILL.md).

This bundle scaffolds **autopoietic skills**: domain-bounded helpers that cache their own reference knowledge to disk, refuse out-of-scope requests, and learn new in-scope capabilities on demand.

## Quick start (any harness honoring AGENTS.md)

1. Read [skills/autopoietic-builder/SKILL.md](skills/autopoietic-builder/SKILL.md)
2. To scaffold a new skill from outside Claude Code, use the portable shell scaffolder:
   ```
   ./bin/scaffold-autopoietic-skill <name> --mission "<domain>" --target <dir>
   ```
3. The generated skill is fully self-contained: it carries its own copy of the growth protocol, anti-poisoning rules, verification recipes, and resume-state machine. It runs in any harness, including ones that have never heard of this plugin.

## Spec

Generated skills (and this bundle itself) follow the [agentskills.io specification](https://agentskills.io/specification). Validate any output with [skills-ref](https://github.com/agentskills/agentskills/tree/main/skills-ref):

```
skills-ref validate <skill-dir>
```
