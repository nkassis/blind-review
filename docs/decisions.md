# Decisions

One line per deviation from a global default or other design choice, newest last: `YYYY-MM-DD - what was chosen - why`.

- 2026-11-02 - Repo, marketplace, plugin and skill are all named `blind-review` - NIM-164 default; plugin namespacing and the repo-qualified install keep it apart from other `blind-review` skills, and the README says how it differs.
- 2026-11-02 - The repo root is both marketplace root and plugin root (`"source": "./"`) - one plugin, so a `plugins/` subdirectory would only add a level; the marketplace reference documents root sources.
- 2026-11-02 - `plugin.json` sets `version` 1.0.0 - without it `claude plugin validate` warns; the cost is that users get a skill change only after the version is bumped.
- 2026-11-02 - Tests are one bash script with python3 stdlib, not pytest - no Python package here and no new dependency; frontmatter is parsed as `key: value` lines, and any unquoted value YAML would not read as a plain string (a leading `[`, `{`, `*`, `&`, `!`, `|`, `>` and similar, or `: ` / ` #` inside) fails the test, since stdlib has no YAML parser.
- 2026-11-02 - The heading test checks `## Inputs`, `## Steps`, `## Notes` as headings and Report structure plus its six sections as bold numbered items under Steps - that is how the source SKILL.md writes them, and the issue requires the text unchanged.
- 2026-11-02 - No root `CLAUDE.md`; `AGENTS.md` only - `claude plugin validate` warns on a `CLAUDE.md` at a plugin root, and claude-code-patterns makes the same choice.
- 2026-11-02 - CI does not run `claude plugin validate` - it would mean installing the Claude Code CLI on the runner; the JSON and path checks in `make test` cover the manifests and validate is run locally.
- 2026-11-02 - The guard hook is copied into `.claude/hooks/` rather than referenced - claude-code-patterns runs it in place from `security/`, which does not exist here.
- 2026-11-02 - SKILL.md was copied from claude-code-patterns at 6d820cc with one change: `argument-hint` is quoted (`"[mode] [audience]"`) - unquoted it is invalid YAML and Claude Code drops the whole frontmatter; claude-code-patterns gets the same fix in NIM-167.
- 2026-11-02 - Claude Code 2.1.101 warns during `claude plugin validate` that the marketplace's top-level `description` is not accepted, but installs fine - known warning, not treated as a bug; 2.1.316 does not show it.
- 2026-11-02 - The guard hook here now differs from the claude-code-patterns copy: it handles `-C<path>` and `--git-dir` (both forms) and is tested in `tests/run.sh` - both were bypasses found in the PR #1 review (NIM-166); NIM-167 ports the fix back.
