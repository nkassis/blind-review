#!/usr/bin/env bash
# Checks for the skill, the README, the plugin manifests and the manual installs.
# Needs bash and python3 (stdlib only). Prints PASS/FAIL per check; exits 1 on any FAIL.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_DIR="$ROOT/skills/blind-review"
SKILL="$SKILL_DIR/SKILL.md"
# The skills docs truncate description + when_to_use at 1,536 characters in the listing.
DESCRIPTION_LIMIT=1536
EM_DASH=$'\xe2\x80\x94'

failures=0

pass() { printf 'PASS  %s\n' "$1"; }
fail() {
    printf 'FAIL  %s\n' "$1"
    [[ -z "${2:-}" ]] || printf '      %s\n' "$2"
    failures=$((failures + 1))
}

# Run a python3 check: it prints nothing and exits 0 on success, or prints why and exits 1.
check_py() {
    local label="$1" out
    shift
    if out="$(python3 - "$@" 2>&1)"; then
        pass "$label"
    else
        fail "$label" "$out"
    fi
}

check_frontmatter() {
    check_py "SKILL.md frontmatter parses; name matches directory; description under $DESCRIPTION_LIMIT chars" \
        "$SKILL" "$(basename "$SKILL_DIR")" "$DESCRIPTION_LIMIT" <<'PY'
import re, sys
path, dirname, limit = sys.argv[1], sys.argv[2], int(sys.argv[3])
lines = open(path, encoding="utf-8").read().split("\n")
if lines[0] != "---" or "---" not in lines[1:]:
    sys.exit("no frontmatter block delimited by --- lines")
fields = {}
for line in lines[1:lines.index("---", 1)]:
    m = re.fullmatch(r"([a-z][a-z0-9-]*): (.+)", line)
    if not m:
        sys.exit(f"unparseable frontmatter line: {line!r}")
    if m[1] in fields:
        sys.exit(f"duplicate key: {m[1]}")
    fields[m[1]] = m[2]
if fields.get("name") != dirname:
    sys.exit(f"name {fields.get('name')!r} does not match directory {dirname!r}")
desc = fields.get("description", "")
if not desc.strip():
    sys.exit("description missing")
if len(desc) >= limit:
    sys.exit(f"description is {len(desc)} chars, limit {limit}")
PY
}

check_headings() {
    check_py "SKILL.md has Inputs, Steps, Report structure (six sections), Notes" "$SKILL" <<'PY'
import sys
text = open(sys.argv[1], encoding="utf-8").read()
lines = text.split("\n")
missing = [h for h in ("## Inputs", "## Steps", "## Notes") if h not in lines]
if missing:
    sys.exit(f"missing headings: {missing}")
steps = text[text.index("\n## Steps\n"):text.index("\n## Notes\n")]
if "**Report structure**" not in steps:
    sys.exit("no **Report structure** under ## Steps")
report = steps[steps.index("**Report structure**"):]
pos = 0
for n, name in enumerate(["Verdict", "Brief coverage", "Findings", "Consistency", "Judgment", "Keep"], 1):
    label = f"{n}. **{name}**"
    found = report.find(label, pos)
    if found < 0:
        sys.exit(f"report section missing or out of order: {label}")
    pos = found
PY
}

check_no_em_dashes() {
    local file
    for file in "$SKILL" "$ROOT/README.md"; do
        if grep -n "$EM_DASH" "$file" >/dev/null; then
            fail "no em dashes in ${file#"$ROOT"/}" "$(grep -n "$EM_DASH" "$file" | head -5)"
        else
            pass "no em dashes in ${file#"$ROOT"/}"
        fi
    done
}

check_manifests() {
    check_py "marketplace.json and plugin.json are valid JSON and every path they reference exists" "$ROOT" <<'PY'
import json, os, sys
root = sys.argv[1]
def load(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError) as e:
        sys.exit(f"{os.path.relpath(path, root)}: {e}")
def paths_in(value):
    if isinstance(value, str) and (value.startswith("./") or value == "."):
        yield value
    elif isinstance(value, dict):
        for v in value.values():
            yield from paths_in(v)
    elif isinstance(value, list):
        for v in value:
            yield from paths_in(v)
def check_exists(base, rel, where):
    if ".." in rel.split("/"):
        sys.exit(f"{where}: path contains '..': {rel}")
    if not os.path.exists(os.path.join(base, rel)):
        sys.exit(f"{where}: path not found: {rel}")
market = load(os.path.join(root, ".claude-plugin", "marketplace.json"))
for key in ("name", "owner", "plugins"):
    if key not in market:
        sys.exit(f"marketplace.json: missing {key}")
if not market["plugins"]:
    sys.exit("marketplace.json: no plugins")
for rel in paths_in(market):
    check_exists(root, rel, "marketplace.json")
for entry in market["plugins"]:
    plugin_root = os.path.normpath(os.path.join(root, entry["source"]))
    manifest = load(os.path.join(plugin_root, ".claude-plugin", "plugin.json"))
    if manifest.get("name") != entry["name"]:
        sys.exit(f"entry name {entry['name']!r} differs from plugin.json name {manifest.get('name')!r}")
    for rel in paths_in(manifest):
        check_exists(plugin_root, rel, "plugin.json")
    skill = os.path.join(plugin_root, "skills", "blind-review", "SKILL.md")
    if not os.path.isfile(skill):
        sys.exit(f"plugin {entry['name']!r} has no skills/blind-review/SKILL.md")
PY
}

# Global manual install: symlink the skill directory into a scratch HOME.
check_symlink_install() {
    local home target
    home="$(mktemp -d)"
    mkdir -p "$home/.claude/skills"
    ln -s "$SKILL_DIR" "$home/.claude/skills/blind-review"
    target="$home/.claude/skills/blind-review/SKILL.md"
    if [[ -L "$home/.claude/skills/blind-review" && -f "$target" ]] && cmp -s "$target" "$SKILL"; then
        pass "symlink install: ~/.claude/skills/blind-review/SKILL.md resolves"
    else
        fail "symlink install: ~/.claude/skills/blind-review/SKILL.md resolves"
    fi
    rm -rf "$home"
}

# Project-local install: copy the skill directory into a scratch repo's .claude/skills/.
check_project_install() {
    local project
    project="$(mktemp -d)"
    mkdir -p "$project/.claude/skills"
    cp -R "$SKILL_DIR" "$project/.claude/skills/"
    if cmp -s "$project/.claude/skills/blind-review/SKILL.md" "$SKILL"; then
        pass "project install: .claude/skills/blind-review/SKILL.md present"
    else
        fail "project install: .claude/skills/blind-review/SKILL.md present"
    fi
    rm -rf "$project"
}

check_frontmatter
check_headings
check_no_em_dashes
check_manifests
check_symlink_install
check_project_install

if ((failures)); then
    printf '\n%d check(s) failed\n' "$failures"
    exit 1
fi
printf '\nAll checks passed\n'
