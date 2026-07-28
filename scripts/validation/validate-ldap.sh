#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

: "${LDAP_HOST:?Set LDAP_HOST}"
: "${LDAP_PORT:=389}"
ldapsearch -x -H "ldap://${LDAP_HOST}:${LDAP_PORT}" -s base -b '' namingContexts
pass "LDAP root-DSE query completed"
