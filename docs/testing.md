# Testing

Run the deterministic test suite from the repository root:

```sh
bash tests/scaffold-autopoietic-skill.test.sh
```

The suite exercises the portable scaffolder's help output, required-argument validation, invalid-name rejection, successful bundle generation, placeholder substitution, mission-hash generation, copied references, and refusal to overwrite an existing target.

Instrumentation-based line and branch coverage is currently 0% because no shell coverage tool is configured. The behavioral tests execute the scaffolder end to end. They do not automate the Markdown pressure scenarios under `autopoietic-builder/tests`; those require controlled agent sessions and manual evaluation as described in that directory's README.
