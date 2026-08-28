# agentic-harnesses

Agentic Harnesses is a workshop for experimental agent tools. Each subdirectory is one self-contained idea—its own plugin root, README, and tests—so an experiment can be installed and evaluated independently.

The repository currently contains `autopoietic-builder`, a portable shell scaffolder and skill bundle for creating mission-bounded agents that can retain verified knowledge.

## Requirements

- Requires Bash 3.2 or newer
- Standard Unix tools: `awk`, `sed`, `grep`, `cp`, and either `sha256sum` or `shasum`
- Optional: `envsubst` and `skills-ref`

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

## Validation

Run the deterministic scaffolder tests from the repository root:

```sh
bash tests/scaffold-autopoietic-skill.test.sh
```

See [docs/testing.md](docs/testing.md) for the measured coverage and test scope, and [docs/configuration.md](docs/configuration.md) for supported arguments and environment behavior.
