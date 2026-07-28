#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

ns=${NFS_CSI_NAMESPACE:-openshift-csi-driver-nfs-namespace}
oc get csidriver nfs.csi.k8s.io >/dev/null && pass "NFS CSI driver object exists" || fail "NFS CSI driver object missing"
oc get pods -n "$ns" -o wide
not_ready=$(oc get pods -n "$ns" --no-headers | awk '$2 !~ /^[0-9]+\/[0-9]+$/ || $3 != "Running" {count++} END {print count+0}')
[[ "$not_ready" -eq 0 ]] && pass "NFS CSI pods are Running" || fail "$not_ready NFS CSI pods are not Running"
