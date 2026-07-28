#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

: "${NFS_SERVER:=nfs01.lab.example}"
: "${NFS_SHARE:=/scratch/shared/oud_user_projects}"

getent hosts "$NFS_SERVER" >/dev/null && pass "NFS DNS resolves" || fail "NFS DNS does not resolve"
if have nc; then nc -z -w5 "$NFS_SERVER" 2049 && pass "TCP 2049 reachable" || fail "TCP 2049 unreachable"; else skip "nc is unavailable"; fi
if have showmount; then showmount -e "$NFS_SERVER" | grep -F "$NFS_SHARE" && pass "export is visible" || fail "export not visible"; else skip "showmount is unavailable"; fi
