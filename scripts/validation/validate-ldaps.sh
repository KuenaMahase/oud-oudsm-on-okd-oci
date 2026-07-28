#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

: "${LDAPS_HOST:?Set LDAPS_HOST}"
: "${LDAPS_PORT:=636}"
openssl s_client -connect "${LDAPS_HOST}:${LDAPS_PORT}" -servername "$LDAPS_HOST" </dev/null
verify "certificate and trust result require manual review"
