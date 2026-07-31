#!/usr/bin/env bash
set -euo pipefail
# lib.sh is stored beside each validation script.
# shellcheck disable=SC1091
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

: "${NFS_SERVER:=nfs01.lab.example}"
: "${NFS_SHARE:=/scratch/shared/oud_user_projects}"

if getent hosts "$NFS_SERVER" >/dev/null; then
  pass "NFS DNS resolves"
else
  fail "NFS DNS does not resolve"
fi
if have nc; then
  if nc -z -w5 "$NFS_SERVER" 2049; then
    pass "TCP 2049 reachable"
  else
    fail "TCP 2049 unreachable"
  fi
else
  skip "nc is unavailable"
fi
if have showmount; then
  if showmount -e "$NFS_SERVER" | grep -F "$NFS_SHARE"; then
    pass "export is visible"
  else
    fail "export not visible"
  fi
else
  skip "showmount is unavailable"
fi
