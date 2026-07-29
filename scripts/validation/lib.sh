#!/usr/bin/env bash
set -euo pipefail

pass() { printf 'PASS: %s\n' "$*"; }
fail() { printf 'FAIL: %s\n' "$*" >&2; return 1; }
verify() { printf 'VERIFY: %s\n' "$*"; }
skip() { printf 'SKIPPED: %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
