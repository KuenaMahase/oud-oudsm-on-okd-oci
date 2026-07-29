#!/usr/bin/env bash
set -euo pipefail
# lib.sh is stored beside each validation script.
# shellcheck disable=SC1091
source "$(dirname "$0")/lib.sh"

: "${OUD_POD:?Set OUD_POD to one directory-server pod}"
: "${PASSWORD_FILE_IN_POD:?Set PASSWORD_FILE_IN_POD to a mounted protected password file}"
ns=${OUD_NAMESPACE:-oudns}

oc exec -n "$ns" "$OUD_POD" -- /u01/oracle/oud/bin/dsreplication status \
  --hostname localhost --port 1444 \
  --adminUID admin --adminPasswordFile "$PASSWORD_FILE_IN_POD" \
  --trustAll --no-prompt
pass "dsreplication status command completed"
