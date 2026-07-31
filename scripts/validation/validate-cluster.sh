#!/usr/bin/env bash
set -euo pipefail
# lib.sh is stored beside each validation script.
# shellcheck disable=SC1091
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

not_ready=$(oc get nodes --no-headers | awk '$2 != "Ready" {count++} END {print count+0}')
if [[ "$not_ready" -eq 0 ]]; then pass "all nodes are Ready"; else fail "$not_ready nodes are not Ready"; fi

oc get clusteroperators
oc get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded || true
