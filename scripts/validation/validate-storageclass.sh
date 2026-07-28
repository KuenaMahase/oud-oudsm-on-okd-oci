#!/usr/bin/env bash
set -euo pipefail
# lib.sh is stored beside each validation script.
# shellcheck disable=SC1091
source "$(dirname "$0")/lib.sh"

sc=${STORAGE_CLASS:-nfs-rwx}
provisioner=$(oc get sc "$sc" -o jsonpath='{.provisioner}' 2>/dev/null || true)
if [[ "$provisioner" == "nfs.csi.k8s.io" ]]; then
  pass "$sc uses nfs.csi.k8s.io"
else
  fail "$sc provisioner is '$provisioner'"
fi
reclaim=$(oc get sc "$sc" -o jsonpath='{.reclaimPolicy}')
if [[ "$reclaim" == "Retain" ]]; then
  pass "$sc uses Retain"
else
  verify "$sc reclaim policy is $reclaim"
fi
