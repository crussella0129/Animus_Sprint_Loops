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
  printf '# Remote Profile\n\n<!-- sprint-loop-remote-profile-v2 -->\n\n```\n%s\n```\n' \
    "$2" > "$1/docs/work/remote-profile.md"
}

# test_profile_resolves_fields
P="$TMP_ROOT/gh"
write_profile "$P" 'provider: github
base: main
work: dev
mergePolicy: human-approve'
out=$(bash "$RP" --root "$P")
[ "$(printf '%s\n' "$out" | wc -l | tr -d '[:space:]')" = 4 ] || die test_profile_resolves_fields 'expected exactly four output fields'
printf '%s\n' "$out" | grep -qx 'PROVIDER=github' || die test_profile_resolves_fields 'provider'
printf '%s\n' "$out" | grep -qx 'BASE=main' || die test_profile_resolves_fields 'base'
printf '%s\n' "$out" | grep -qx 'WORK=dev' || die test_profile_resolves_fields 'work'
printf '%s\n' "$out" | grep -qx 'MERGEPOLICY=human-approve' || die test_profile_resolves_fields 'mergePolicy'
[ "$(bash "$RP" --root "$P" provider)" = github ] || die test_profile_resolves_fields 'provider field query'
[ "$(bash "$RP" --root "$P" base)" = main ] || die test_profile_resolves_fields 'base field query'
[ "$(bash "$RP" --root "$P" work)" = dev ] || die test_profile_resolves_fields 'work field query'
[ "$(bash "$RP" --root "$P" mergePolicy)" = human-approve ] || die test_profile_resolves_fields 'mergePolicy field query'
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

V1="$TMP_ROOT/v1"; mkdir -p "$V1/docs/work"
printf '# Remote Profile\n\n<!-- sprint-loop-remote-profile-v1 -->\n\n```\nprovider: github\nbase: main\nwork: dev\n```\n' > "$V1/docs/work/remote-profile.md"
if bash "$RP" --root "$V1" >/dev/null 2>"$V1/err"; then die test_profile_rejects_malformed 'legacy marker accepted'; fi
grep -qF 'migrate to sprint-loop-remote-profile-v2' "$V1/err" || die test_profile_rejects_malformed 'no migration diagnostic'

X="$TMP_ROOT/extra"
write_profile "$X" 'provider: github
base: main
work: dev
extra: stale'
if bash "$RP" --root "$X" >/dev/null 2>"$X/err"; then die test_profile_rejects_malformed 'unknown profile field accepted'; fi
grep -qF "unknown profile field 'extra'" "$X/err" || die test_profile_rejects_malformed 'no unknown-field diagnostic'

Q="$TMP_ROOT/query"
write_profile "$Q" 'provider: github
base: main
work: dev'
if bash "$RP" --root "$Q" retired >/dev/null 2>"$Q/err"; then die test_profile_rejects_malformed 'unknown field query accepted'; fi
grep -qF 'expected provider|base|work|mergePolicy' "$Q/err" || die test_profile_rejects_malformed 'no field-query diagnostic'
pass test_profile_rejects_malformed

# test_profile_local_only_valid
L="$TMP_ROOT/local"
write_profile "$L" 'provider: local-only
base: main
work: dev'
out=$(bash "$RP" --root "$L")
[ "$(printf '%s\n' "$out" | wc -l | tr -d '[:space:]')" = 4 ] || die test_profile_local_only_valid 'expected exactly four output fields'
printf '%s\n' "$out" | grep -qx 'PROVIDER=local-only' || die test_profile_local_only_valid 'provider'
printf '%s\n' "$out" | grep -qx 'MERGEPOLICY=human-approve' || die test_profile_local_only_valid 'mergePolicy defaults'
pass test_profile_local_only_valid

# test_profile_accepts_gitea_forgejo — self-hosted forges are declared, not
# inferred, so the enum has to carry them.
for forge in gitea forgejo; do
  F="$TMP_ROOT/$forge"
  write_profile "$F" "provider: $forge
base: main
work: dev"
  [ "$(bash "$RP" --root "$F" provider)" = "$forge" ] ||
    die test_profile_accepts_gitea_forgejo "$forge was not resolved"
  bash "$RP" --root "$F" >/dev/null || die test_profile_accepts_gitea_forgejo "$forge full resolve failed"
done
pass test_profile_accepts_gitea_forgejo

# Widening the enum must not weaken the rejection, and the diagnostic must name
# every accepted value so an operator can see the whole set.
B="$TMP_ROOT/bitbucket-again"
write_profile "$B" 'provider: bitbucket
base: main
work: dev'
if bash "$RP" --root "$B" >/dev/null 2>/dev/null; then
  die test_profile_enum_diagnostic_names_every_value 'unknown provider accepted after widening the enum'
fi
reject_out=$(bash "$RP" --root "$B" 2>&1 || true)
for value in github gitlab gitea forgejo generic local-only; do
  case "$reject_out" in
    *"$value"*) : ;;
    *) die test_profile_enum_diagnostic_names_every_value "diagnostic omits $value: $reject_out" ;;
  esac
done
pass test_profile_enum_diagnostic_names_every_value

printf 'remote-profile selftest: all fixtures passed\n'
