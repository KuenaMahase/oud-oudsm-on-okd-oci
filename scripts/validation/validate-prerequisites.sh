#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

for cmd in oc helm; do
  if have "$cmd"; then pass "$cmd is installed"; else fail "$cmd is not installed"; fi
done

oc whoami >/dev/null 2>&1 && pass "OpenShift authentication works" || fail "OpenShift authentication failed"
oc version
helm version
