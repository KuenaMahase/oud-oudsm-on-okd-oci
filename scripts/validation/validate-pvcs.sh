#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

failed=0
for ns in oudns oudsmns; do
  if ! oc get ns "$ns" >/dev/null 2>&1; then verify "namespace $ns does not exist"; continue; fi
  oc get pvc -n "$ns"
  pending=$(oc get pvc -n "$ns" --no-headers 2>/dev/null | awk '$2 != "Bound" {count++} END {print count+0}')
  if [[ "$pending" -eq 0 ]]; then pass "all PVCs in $ns are Bound"; else printf 'FAIL: %s PVCs in %s are not Bound\n' "$pending" "$ns" >&2; failed=1; fi
done
exit "$failed"
