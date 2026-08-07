#!/usr/bin/env bash
# Fixtures for remote-profile.sh — resolve, reject-malformed, local-only.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RP="$SCRIPT_DIR/remote-profile.sh"
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/sprint-loop-profile.XXXXXX")
trap 'rm -rf "$TMP_ROOT"' EXIT HUP INT TERM

pass() { printf '  PASS  %s\n' "$1"; }
die() { printf '  FAIL  %s: %s\n' "$1" "$2" >&2; exit 1; }

write_profile() {  # <dir> <fenced-body>
  mkdir -p "$1/docs/work"
  printf '# Remote Profile\n\n<!-- sprint-loop-remote-profile-v1 -->\n\n```\n%s\n```\n' \
    "$2" > "$1/docs/work/remote-profile.md"
}

# test_profile_resolves_fields
P="$TMP_ROOT/gh"
write_profile "$P" 'provider: github
base: main
work: dev
bump: bump
mergePolicy: human-approve'
out=$(bash "$RP" --root "$P")
printf '%s\n' "$out" | grep -qx 'PROVIDER=github' || die test_profile_resolves_fields 'provider'
printf '%s\n' "$out" | grep -qx 'BASE=main' || die test_profile_resolves_fields 'base'
printf '%s\n' "$out" | grep -qx 'WORK=dev' || die test_profile_resolves_fields 'work'
printf '%s\n' "$out" | grep -qx 'BUMP=bump' || die test_profile_resolves_fields 'bump'
printf '%s\n' "$out" | grep -qx 'MERGEPOLICY=human-approve' || die test_profile_resolves_fields 'mergePolicy'
[ "$(bash "$RP" --root "$P" work)" = dev ] || die test_profile_resolves_fields 'field query'
pass test_profile_resolves_fields

# test_profile_rejects_malformed
E="$TMP_ROOT/empty"; mkdir -p "$E"
if bash "$RP" --root "$E" >/dev/null 2>/dev/null; then die test_profile_rejects_malformed 'missing file accepted'; fi
U="$TMP_ROOT/unknown"
write_profile "$U" 'provider: bitbucket
base: main
work: dev'
if bash "$RP" --root "$U" >/dev/null 2>"$U/err"; then die test_profile_rejects_malformed 'unknown provider accepted'; fi
grep -qF "unknown provider 'bitbucket'" "$U/err" || die test_profile_rejects_malformed 'no provider diagnostic'
M="$TMP_ROOT/nobase"
write_profile "$M" 'provider: github
work: dev'
if bash "$RP" --root "$M" >/dev/null 2>"$M/err"; then die test_profile_rejects_malformed 'missing base accepted'; fi
grep -qF 'missing required field: base' "$M/err" || die test_profile_rejects_malformed 'no base diagnostic'
NM="$TMP_ROOT/nomarker"; mkdir -p "$NM/docs/work"
printf '```\nprovider: github\nbase: main\nwork: dev\n```\n' > "$NM/docs/work/remote-profile.md"
if bash "$RP" --root "$NM" >/dev/null 2>"$NM/err"; then die test_profile_rejects_malformed 'missing marker accepted'; fi
grep -qF 'marker' "$NM/err" || die test_profile_rejects_malformed 'no marker diagnostic'
pass test_profile_rejects_malformed

# test_profile_local_only_valid
L="$TMP_ROOT/local"
write_profile "$L" 'provider: local-only
base: main
work: dev'
out=$(bash "$RP" --root "$L")
printf '%s\n' "$out" | grep -qx 'PROVIDER=local-only' || die test_profile_local_only_valid 'provider'
printf '%s\n' "$out" | grep -qx 'BUMP=none' || die test_profile_local_only_valid 'bump defaults none'
printf '%s\n' "$out" | grep -qx 'MERGEPOLICY=human-approve' || die test_profile_local_only_valid 'mergePolicy defaults'
pass test_profile_local_only_valid

printf 'remote-profile selftest: all fixtures passed\n'
