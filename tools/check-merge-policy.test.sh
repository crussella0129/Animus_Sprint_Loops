#!/usr/bin/env bash
# Temporary compatibility shim for the canonical guard runner.
# T-120: remove this file when the runner suite is renamed from
# `merge-policy-test` to `adapter-semantics-test`.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$SCRIPT_DIR/check-adapter-semantics.test.sh" "$@"
