#!/usr/bin/env bash
# Canonical local state-machine selftest aggregator.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/check-book.test.sh"
bash "$SCRIPT_DIR/book-routing.test.sh"
bash "$SCRIPT_DIR/migrate-to-book.test.sh"
bash "$SCRIPT_DIR/runtime-helpers.test.sh"
echo 'selftest: all Book contract, routing, migration, and runtime fixtures passed'
