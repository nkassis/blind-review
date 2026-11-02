# Decisions

One line per deviation from a global default or other design choice, newest last: `YYYY-MM-DD - what was chosen - why`.

- 2026-11-02 - Repo, marketplace, plugin and skill are all named `blind-review` - NIM-164 default; plugin namespacing and the repo-qualified install keep it apart from other `blind-review` skills, and the README says how it differs.
- 2026-11-02 - The repo root is both marketplace root and plugin root (`"source": "./"`) - one plugin, so a `plugins/` subdirectory would only add a level; the marketplace reference documents root sources.
- 2026-11-02 - `plugin.json` sets `version` 1.0.0 - without it `claude plugin validate` warns; the cost is that users get a skill change only after the version is bumped.
- 2026-11-02 - Tests are one bash script with python3 stdlib, not pytest - no Python package here and no new dependency; frontmatter is parsed as `key: value` lines because `argument-hint: [mode] [audience]` is not valid YAML, though Claude Code accepts it.
- 2026-11-02 - The heading test checks `## Inputs`, `## Steps`, `## Notes` as headings and Report structure plus its six sections as bold numbered items under Steps - that is how the source SKILL.md writes them, and the issue requires the text unchanged.
- 2026-11-02 - No root `CLAUDE.md`; `AGENTS.md` only - `claude plugin validate` warns on a `CLAUDE.md` at a plugin root, and claude-code-patterns makes the same choice.
- 2026-11-02 - CI does not run `claude plugin validate` - it would mean installing the Claude Code CLI on the runner; the JSON and path checks in `make test` cover the manifests and validate is run locally.
- 2026-11-02 - The guard hook is copied into `.claude/hooks/` rather than referenced - claude-code-patterns runs it in place from `security/`, which does not exist here.
