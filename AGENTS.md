# AGENTS.md

Commands run from the repo root.

## Layout

- `skills/blind-review/SKILL.md`: the skill. Canonical copy; claude-code-patterns vendors it from here.
- `.claude-plugin/marketplace.json` + `.claude-plugin/plugin.json`: the repo root is both the marketplace root and the plugin root (`"source": "./"`). Entry name and manifest name stay `blind-review`.
- `tests/run.sh`: every check, bash and python3 stdlib only.

## Checks

CI (`.github/workflows/ci.yml`, job name `ci`) runs these on every PR and push to main; `secret-scan.yml` runs TruffleHog.

| Command | What it does |
| --- | --- |
| `make test` | SKILL.md frontmatter and headings, no em dashes in SKILL.md or README.md, manifests parse and their paths exist, symlink and project-copy installs into scratch directories |
| `shellcheck .claude/hooks/*.sh tests/*.sh` | Every script is shellcheck-clean |
| `claude plugin validate .` | Local only (the CLI is not on the runner). Run after any manifest change |

## Guarding main

`.claude/settings.json` runs `.claude/hooks/guard-bash.sh` before every Bash call; it is a copy of `security/.claude/hooks/guard-bash.sh` from claude-code-patterns, tested there. `.pre-commit-config.yaml` has `no-commit-to-branch`; run `pre-commit install` once per clone.
