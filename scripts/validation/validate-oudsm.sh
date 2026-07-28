#!/usr/bin/env bash
set -euo pipefail
# lib.sh is stored beside each validation script.
# shellcheck disable=SC1091
source "$(dirname "$0")/lib.sh"

ns=${OUDSM_NAMESPACE:-oudsmns}
oc get deployment,pods,svc,pvc,route -n "$ns" -o wide
route_count=$(oc get route -n "$ns" --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [[ "$route_count" -gt 0 ]]; then
  pass "OUDSM namespace has a Route"
else
  verify "no OUDSM Route found"
fi
