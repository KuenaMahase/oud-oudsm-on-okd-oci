#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

sc=${STORAGE_CLASS:-nfs-rwx}
provisioner=$(oc get sc "$sc" -o jsonpath='{.provisioner}' 2>/dev/null || true)
[[ "$provisioner" == "nfs.csi.k8s.io" ]] && pass "$sc uses nfs.csi.k8s.io" || fail "$sc provisioner is '$provisioner'"
reclaim=$(oc get sc "$sc" -o jsonpath='{.reclaimPolicy}')
[[ "$reclaim" == "Retain" ]] && pass "$sc uses Retain" || verify "$sc reclaim policy is $reclaim"
