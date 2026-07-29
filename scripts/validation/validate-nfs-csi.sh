#!/usr/bin/env bash
set -euo pipefail
# lib.sh is stored beside each validation script.
# shellcheck disable=SC1091
source "$(dirname "$0")/lib.sh"

ns=${NFS_CSI_NAMESPACE:-openshift-csi-driver-nfs-namespace}
if oc get csidriver nfs.csi.k8s.io >/dev/null; then
  pass "NFS CSI driver object exists"
else
  fail "NFS CSI driver object missing"
fi
oc get pods -n "$ns" -o wide
not_ready=$(oc get pods -n "$ns" --no-headers | awk '$2 !~ /^[0-9]+\/[0-9]+$/ || $3 != "Running" {count++} END {print count+0}')
if [[ "$not_ready" -eq 0 ]]; then
  pass "NFS CSI pods are Running"
else
  fail "$not_ready NFS CSI pods are not Running"
fi
