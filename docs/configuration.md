# Configuration

The repository does not require secrets or a configuration file. Configure the portable scaffolder with command-line arguments:

```sh
./autopoietic-builder/bin/scaffold-autopoietic-skill NAME \
  --mission "DOMAIN" \
  --target PATH
```

Optional arguments are `--license`, `--allowed-tools`, `--in-scope-file`, and `--out-of-scope-file`. Run the command with `--help` for its usage summary.

When `--target` is omitted, the script writes beneath `${HOME}/.claude/skills`. Pass an explicit target in automation. The script uses no API tokens and makes no network calls. If `skills-ref` is installed, the generated skill is validated with it automatically.
