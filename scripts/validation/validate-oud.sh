#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

ns=${OUD_NAMESPACE:-oudns}
oc get statefulset,pods,svc,pvc -n "$ns" -o wide
pods=$(oc get pods -n "$ns" -l app.kubernetes.io/name=oud --no-headers 2>/dev/null | wc -l | tr -d ' ')
[[ "$pods" -gt 0 ]] && pass "found OUD-labelled pods" || verify "chart labels differ or OUD pods are missing"
