#!/usr/bin/env bash
# Print the current (highest-numbered) sprint number, or -1 if uninitialized.
set -euo pipefail
if [ ! -d sprints ]; then echo "-1"; exit 0; fi
ls sprints/ 2>/dev/null | grep -E '^s[0-9]+$' | sed 's/^s//' | sort -n | tail -1 || echo "-1"
