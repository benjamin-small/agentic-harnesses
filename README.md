# agentic-harnesses

A workshop repo. Each subdirectory is one self-contained idea — its own plugin root, its own README, its own tests.

## Conventions

- One idea per top-level subdirectory (e.g. `autopoietic-builder/`)
- Each idea is the root of its own Claude Code plugin (`<idea>/.claude-plugin/plugin.json`) and the root of its own [agentskills.io](https://agentskills.io/specification)-compliant skill bundle
- The repo root holds only cross-cutting concerns (this README, repo-wide `.gitignore`)
- Ideas are individually installable, individually portable, and do not depend on each other

## Ideas

| Idea | Status | One-liner |
|------|--------|-----------|
| [`autopoietic-builder/`](./autopoietic-builder/) | active | Scaffolds self-modifying, knowledge-caching, mission-bounded skills and agents |

## Adding a new idea

```
agentic-harnesses/
└── <new-idea>/
    ├── .claude-plugin/plugin.json   # if it's a CC plugin
    ├── README.md                    # what it does, install, usage
    ├── AGENTS.md                    # cross-harness pointer
    └── ...                          # any structure the idea needs
```

Add a row to the table above.
