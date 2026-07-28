#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

ns=${OUD_NAMESPACE:-oudns}
oc get pods -n "$ns" -l app.kubernetes.io/name=oud-proxy -o wide
oc get svc -n "$ns" oud-proxy-ldap-public -o yaml >/dev/null && pass "LDAP public Service exists" || verify "LDAP Service name differs or is absent"

if [[ -z "${PROXY_POD:-}" || -z "${PASSWORD_FILE_IN_POD:-}" ]]; then
  verify "set PROXY_POD and PASSWORD_FILE_IN_POD to inspect dsconfig objects"
  exit 0
fi
DS=/u01/oracle/oud/bin/dsconfig
for action in list-extensions list-workflow-elements list-workflows list-network-groups; do
  oc exec -n "$ns" "$PROXY_POD" -- "$DS" -h localhost -p 1444 \
    -D 'cn=Directory Manager' -j "$PASSWORD_FILE_IN_POD" -X -n "$action"
done
pass "OUD Proxy configuration objects listed"
