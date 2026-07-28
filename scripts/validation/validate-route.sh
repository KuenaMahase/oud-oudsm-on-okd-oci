#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

ns=${OUDSM_NAMESPACE:-oudsmns}
: "${ROUTE_NAME:?Set ROUTE_NAME}"
route_json=$(oc get route -n "$ns" "$ROUTE_NAME" -o json)
printf '%s\n' "$route_json" | python3 -m json.tool
host=$(oc get route -n "$ns" "$ROUTE_NAME" -o jsonpath='{.spec.host}')
termination=$(oc get route -n "$ns" "$ROUTE_NAME" -o jsonpath='{.spec.tls.termination}')
printf 'Host: %s\nTermination: %s\n' "$host" "$termination"
pass "Route object retrieved"
