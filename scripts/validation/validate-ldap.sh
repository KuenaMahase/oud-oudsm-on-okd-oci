#!/usr/bin/env bash
set -euo pipefail
# lib.sh is stored beside each validation script.
# shellcheck disable=SC1091
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

: "${LDAP_HOST:?Set LDAP_HOST}"
: "${LDAP_PORT:=389}"
ldapsearch -x -H "ldap://${LDAP_HOST}:${LDAP_PORT}" -s base -b '' namingContexts
pass "LDAP root-DSE query completed"
