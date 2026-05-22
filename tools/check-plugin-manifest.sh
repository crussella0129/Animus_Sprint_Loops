#!/usr/bin/env bash
# Validates the Claude Code plugin packaging:
#   - repo-root .claude-plugin/marketplace.json is valid JSON, has a name, and a
#     plugins[] entry named "sprint-loop" whose source is "./claude-code"
#   - the source dir resolves to a tree containing skills/sprint-loop/SKILL.md
#   - <source>/.claude-plugin/plugin.json is valid JSON with name == "sprint-loop"
# Exits non-zero with a message naming the failed assertion. No deps beyond python3
# (jq is frequently absent on Windows git-bash).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() { echo "check-plugin-manifest: FAIL — $1" >&2; exit 1; }

MKT="$ROOT/.claude-plugin/marketplace.json"
[ -f "$MKT" ] || fail "marketplace.json missing at $MKT"

# Single python pass does all structural assertions; prints the resolved source path.
SRC="$(ROOT="$ROOT" MKT="$MKT" python3 - <<'PY'
import json, os, sys
root = os.environ["ROOT"]
mkt  = os.environ["MKT"]
try:
    m = json.load(open(mkt, encoding="utf-8"))
except Exception as e:
    print(f"ERR marketplace.json not valid JSON: {e}", file=sys.stderr); sys.exit(2)
if not m.get("name"):
    print("ERR marketplace.json has no 'name'", file=sys.stderr); sys.exit(3)
plugins = m.get("plugins") or []
entry = next((p for p in plugins if p.get("name") == "sprint-loop"), None)
if entry is None:
    print("ERR no plugins[] entry named 'sprint-loop'", file=sys.stderr); sys.exit(4)
src = entry.get("source")
if src != "./claude-code":
    print(f"ERR sprint-loop source is {src!r}, expected './claude-code'", file=sys.stderr); sys.exit(5)
print(src)
PY
)" || fail "marketplace.json structural check failed (see message above)"

# Resolve the source dir relative to repo root and check it carries the skill.
SRCDIR="$ROOT/${SRC#./}"
[ -d "$SRCDIR" ] || fail "plugin source dir does not exist: $SRCDIR"
[ -f "$SRCDIR/skills/sprint-loop/SKILL.md" ] || fail "plugin source missing skills/sprint-loop/SKILL.md under $SRCDIR"

# Regression guard (sprint 10): the skill IS /sprint-loop via its argument-hint.
# A same-named commands/sprint-loop.md would be a DUPLICATE definition of the
# slash command (a command and a same-named skill load identically), reviving
# the picker-duplication this packaging fixed. Refuse it.
[ -f "$SRCDIR/commands/sprint-loop.md" ] && fail "duplicate-command regression: $SRCDIR/commands/sprint-loop.md exists — the skill already provides /sprint-loop; remove the command file"
[ -d "$SRCDIR/commands" ] && fail "skill-only plugin must not ship a commands/ dir ($SRCDIR/commands) — the skill provides /sprint-loop; remove the (possibly empty) directory"
grep -q '^argument-hint:' "$SRCDIR/skills/sprint-loop/SKILL.md" || fail "skills/sprint-loop/SKILL.md lacks an 'argument-hint:' line — it must carry it to be the /sprint-loop slash command without a separate command file"

PJ="$SRCDIR/.claude-plugin/plugin.json"
[ -f "$PJ" ] || fail "plugin.json missing at $PJ"
PJ="$PJ" python3 - <<'PY' || exit 1
import json, os, sys
pj = os.environ["PJ"]
try:
    p = json.load(open(pj, encoding="utf-8"))
except Exception as e:
    print(f"check-plugin-manifest: FAIL — plugin.json not valid JSON: {e}", file=sys.stderr); sys.exit(1)
if p.get("name") != "sprint-loop":
    print(f"check-plugin-manifest: FAIL — plugin.json name is {p.get('name')!r}, expected 'sprint-loop'", file=sys.stderr); sys.exit(1)
PY

echo "check-plugin-manifest: OK — marketplace 'sprint-loop' -> $SRC (skill + plugin.json verified)"
