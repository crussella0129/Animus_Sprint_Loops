#!/usr/bin/env bash
# Fixtures for check-plugin-manifest.sh — bundle-identity assertions (sprint 17).
# Each case mutates an isolated copy of the real packaging surface, so a passing
# baseline plus an independently failing mutation proves the assertion binds.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUARD="$ROOT/tools/check-plugin-manifest.sh"
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/sprint-loop-manifest.XXXXXX")
trap 'rm -rf "$TMP_ROOT"' EXIT HUP INT TERM
pass() { printf '  PASS  %s\n' "$1"; }
die() { printf '  FAIL  %s: %s\n' "$1" "$2" >&2; exit 1; }

# Build a minimal but real fixture: only the files the guard actually reads.
make_fixture() {  # <name> -> prints the fixture root
  local f="$TMP_ROOT/$1"
  mkdir -p "$f/.claude-plugin" \
           "$f/claude-code/.claude-plugin" \
           "$f/claude-code/skills/sprint-loop/scripts"
  cp "$ROOT/.claude-plugin/marketplace.json" "$f/.claude-plugin/marketplace.json"
  cp "$ROOT/claude-code/.claude-plugin/plugin.json" "$f/claude-code/.claude-plugin/plugin.json"
  cp "$ROOT/claude-code/skills/sprint-loop/SKILL.md" "$f/claude-code/skills/sprint-loop/SKILL.md"
  cp "$ROOT/claude-code/skills/sprint-loop/scripts/bundle-version.sh" \
     "$f/claude-code/skills/sprint-loop/scripts/bundle-version.sh"
  printf '%s' "$f"
}
guard() { PLUGIN_MANIFEST_ROOT="$1" bash "$GUARD" 2>&1; }
set_plugin_json() {  # <fixture> <python-mutation>
  FIXTURE="$1" MUTATION="$2" python3 - <<'PY'
import json, os
pj = os.path.join(os.environ["FIXTURE"], "claude-code", ".claude-plugin", "plugin.json")
with open(pj, encoding="utf-8") as fh:
    data = json.load(fh)
exec(os.environ["MUTATION"], {"data": data})
with open(pj, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2)
    fh.write("\n")
PY
}

# test_manifest_baseline_passes — the real packaging surface is valid.
B=$(make_fixture baseline)
guard "$B" >/dev/null 2>&1 || die test_manifest_baseline_passes "baseline failed: $(guard "$B")"
case "$(guard "$B")" in *'plugin.json v'*) : ;; *) die test_manifest_baseline_passes "no version in OK line: $(guard "$B")" ;; esac
pass test_manifest_baseline_passes

# test_bundle_version_prints_single_line
BV="$B/claude-code/skills/sprint-loop/scripts/bundle-version.sh"
[ "$(bash "$BV" | wc -l | tr -d '[:space:]')" = 1 ] ||
  die test_bundle_version_prints_single_line 'bundle-version.sh did not print exactly one line'
[ -n "$(bash "$BV")" ] || die test_bundle_version_prints_single_line 'bundle-version.sh printed nothing'
bash "$BV" >/dev/null || die test_bundle_version_prints_single_line 'bundle-version.sh exited non-zero'
pass test_bundle_version_prints_single_line

# test_manifest_requires_version
NV=$(make_fixture no-version)
set_plugin_json "$NV" 'data.pop("version", None)'
if guard "$NV" >/dev/null 2>&1; then die test_manifest_requires_version 'missing version accepted'; fi
case "$(guard "$NV")" in *"no 'version' field"*) : ;; *) die test_manifest_requires_version "diagnostic does not name the field: $(guard "$NV")" ;; esac
pass test_manifest_requires_version

# test_manifest_version_must_match_bundle
MM=$(make_fixture mismatch)
set_plugin_json "$MM" 'data["version"] = "9.9.9"'
if guard "$MM" >/dev/null 2>&1; then die test_manifest_version_must_match_bundle 'mismatched version accepted'; fi
mm_out=$(guard "$MM")
case "$mm_out" in *'9.9.9'*) : ;; *) die test_manifest_version_must_match_bundle "diagnostic omits the manifest value: $mm_out" ;; esac
case "$mm_out" in *"$(bash "$BV")"*) : ;; *) die test_manifest_version_must_match_bundle "diagnostic omits the bundle value: $mm_out" ;; esac
pass test_manifest_version_must_match_bundle

# test_manifest_rejects_multiline_bundle_version
ML=$(make_fixture multiline)
printf '#!/usr/bin/env bash\nprintf %s\n' "'0.0.1\\n0.0.2\\n'" \
  > "$ML/claude-code/skills/sprint-loop/scripts/bundle-version.sh"
if guard "$ML" >/dev/null 2>&1; then die test_manifest_rejects_multiline_bundle_version 'multi-line version accepted'; fi
case "$(guard "$ML")" in *'exactly one line'*) : ;; *) die test_manifest_rejects_multiline_bundle_version "unexpected diagnostic: $(guard "$ML")" ;; esac
pass test_manifest_rejects_multiline_bundle_version

# test_manifest_requires_bundle_version_helper
NH=$(make_fixture no-helper)
rm -f "$NH/claude-code/skills/sprint-loop/scripts/bundle-version.sh"
if guard "$NH" >/dev/null 2>&1; then die test_manifest_requires_bundle_version_helper 'missing helper accepted'; fi
case "$(guard "$NH")" in *'bundle version helper missing'*) : ;; *) die test_manifest_requires_bundle_version_helper "unexpected diagnostic: $(guard "$NH")" ;; esac
pass test_manifest_requires_bundle_version_helper

printf 'check-plugin-manifest selftest: all fixtures passed\n'
