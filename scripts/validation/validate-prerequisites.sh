#!/usr/bin/env bash
set -euo pipefail
# lib.sh is stored beside each validation script.
# shellcheck disable=SC1091
source "$(dirname "$0")/lib.sh"

for cmd in oc helm; do
  if have "$cmd"; then pass "$cmd is installed"; else fail "$cmd is not installed"; fi
done

if oc whoami >/dev/null 2>&1; then
  pass "OpenShift authentication works"
else
  fail "OpenShift authentication failed"
fi
oc version
helm version
