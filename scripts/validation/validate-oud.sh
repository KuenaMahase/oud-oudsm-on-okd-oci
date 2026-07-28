#!/usr/bin/env bash
set -euo pipefail
# lib.sh is stored beside each validation script.
# shellcheck disable=SC1091
source "$(dirname "$0")/lib.sh"

ns=${OUD_NAMESPACE:-oudns}
oc get statefulset,pods,svc,pvc -n "$ns" -o wide
pods=$(oc get pods -n "$ns" -l app.kubernetes.io/name=oud --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [[ "$pods" -gt 0 ]]; then
  pass "found OUD-labelled pods"
else
  verify "chart labels differ or OUD pods are missing"
fi
