#!/usr/bin/env bash
# Print this Sprint Loops bundle's version.
#
# The version lives inside the bundle rather than only in the Claude Code
# plugin manifest because the manual installer copies skills/<name>/ with no
# .claude-plugin/ directory beside it — a manifest-only version is unreadable
# in that install mode, and the sprint record has to name the bundle that ran
# the sprint in every mode. tools/check-plugin-manifest.sh requires
# plugin.json's "version" to equal this value; the cross-bundle parity guard
# requires all four copies to be byte-identical.
set -euo pipefail
printf '%s\n' 0.22.0
