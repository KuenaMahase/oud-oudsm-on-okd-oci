#!/usr/bin/env bash
set -euo pipefail
# lib.sh is stored beside each validation script.
# shellcheck disable=SC1091
source "$(dirname "$0")/lib.sh"

: "${NAMESPACE:?Set NAMESPACE}"
: "${POD:?Set POD}"
: "${MOUNT_PATH:?Set MOUNT_PATH}"
marker="portfolio-persistence-$(date +%s)"
oc exec -n "$NAMESPACE" "$POD" -- sh -c "printf '%s' '$marker' > '$MOUNT_PATH/.portfolio-marker'"
oc delete pod -n "$NAMESPACE" "$POD" --wait=true
verify "identify the recreated pod and confirm $MOUNT_PATH/.portfolio-marker contains $marker"
