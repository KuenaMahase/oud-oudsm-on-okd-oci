#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

ns=${OUDSM_NAMESPACE:-oudsmns}
oc get deployment,pods,svc,pvc,route -n "$ns" -o wide
route_count=$(oc get route -n "$ns" --no-headers 2>/dev/null | wc -l | tr -d ' ')
[[ "$route_count" -gt 0 ]] && pass "OUDSM namespace has a Route" || verify "no OUDSM Route found"
