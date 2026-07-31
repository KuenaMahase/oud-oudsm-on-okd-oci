#!/usr/bin/env python3
"""Refactor validation scripts so the repository's ShellCheck job passes."""
from pathlib import Path

root = Path(__file__).resolve().parents[2]
validation = root / "scripts" / "validation"

for path in validation.glob("validate-*.sh"):
    text = path.read_text(encoding="utf-8")
    source = 'source "$(dirname "$0")/lib.sh"'
    if source in text and "shellcheck source=lib.sh" not in text:
        text = text.replace(
            source,
            '# shellcheck source=lib.sh\n' + source,
            1,
        )
    path.write_text(text, encoding="utf-8")

replacements = {
    "validate-prerequisites.sh": {
        'oc whoami >/dev/null 2>&1 && pass "OpenShift authentication works" || fail "OpenShift authentication failed"':
        '''if oc whoami >/dev/null 2>&1; then
  pass "OpenShift authentication works"
else
  fail "OpenShift authentication failed"
fi''',
    },
    "validate-oudsm.sh": {
        '[[ "$route_count" -gt 0 ]] && pass "OUDSM namespace has a Route" || verify "no OUDSM Route found"':
        '''if [[ "$route_count" -gt 0 ]]; then
  pass "OUDSM namespace has a Route"
else
  verify "no OUDSM Route found"
fi''',
    },
    "validate-storageclass.sh": {
        '[[ "$provisioner" == "nfs.csi.k8s.io" ]] && pass "$sc uses nfs.csi.k8s.io" || fail "$sc provisioner is \'$provisioner\'"':
        '''if [[ "$provisioner" == "nfs.csi.k8s.io" ]]; then
  pass "$sc uses nfs.csi.k8s.io"
else
  fail "$sc provisioner is '$provisioner'"
fi''',
        '[[ "$reclaim" == "Retain" ]] && pass "$sc uses Retain" || verify "$sc reclaim policy is $reclaim"':
        '''if [[ "$reclaim" == "Retain" ]]; then
  pass "$sc uses Retain"
else
  verify "$sc reclaim policy is $reclaim"
fi''',
    },
    "validate-nfs-csi.sh": {
        'oc get csidriver nfs.csi.k8s.io >/dev/null && pass "NFS CSI driver object exists" || fail "NFS CSI driver object missing"':
        '''if oc get csidriver nfs.csi.k8s.io >/dev/null; then
  pass "NFS CSI driver object exists"
else
  fail "NFS CSI driver object missing"
fi''',
        '[[ "$not_ready" -eq 0 ]] && pass "NFS CSI pods are Running" || fail "$not_ready NFS CSI pods are not Running"':
        '''if [[ "$not_ready" -eq 0 ]]; then
  pass "NFS CSI pods are Running"
else
  fail "$not_ready NFS CSI pods are not Running"
fi''',
    },
    "validate-nfs-server.sh": {
        'getent hosts "$NFS_SERVER" >/dev/null && pass "NFS DNS resolves" || fail "NFS DNS does not resolve"':
        '''if getent hosts "$NFS_SERVER" >/dev/null; then
  pass "NFS DNS resolves"
else
  fail "NFS DNS does not resolve"
fi''',
        'if have nc; then nc -z -w5 "$NFS_SERVER" 2049 && pass "TCP 2049 reachable" || fail "TCP 2049 unreachable"; else skip "nc is unavailable"; fi':
        '''if have nc; then
  if nc -z -w5 "$NFS_SERVER" 2049; then
    pass "TCP 2049 reachable"
  else
    fail "TCP 2049 unreachable"
  fi
else
  skip "nc is unavailable"
fi''',
        'if have showmount; then showmount -e "$NFS_SERVER" | grep -F "$NFS_SHARE" && pass "export is visible" || fail "export not visible"; else skip "showmount is unavailable"; fi':
        '''if have showmount; then
  if showmount -e "$NFS_SERVER" | grep -F "$NFS_SHARE"; then
    pass "export is visible"
  else
    fail "export not visible"
  fi
else
  skip "showmount is unavailable"
fi''',
    },
    "validate-oud-proxy.sh": {
        'oc get svc -n "$ns" oud-proxy-ldap-public -o yaml >/dev/null && pass "LDAP public Service exists" || verify "LDAP Service name differs or is absent"':
        '''if oc get svc -n "$ns" oud-proxy-ldap-public -o yaml >/dev/null; then
  pass "LDAP public Service exists"
else
  verify "LDAP Service name differs or is absent"
fi''',
    },
    "validate-oud.sh": {
        '[[ "$pods" -gt 0 ]] && pass "found OUD-labelled pods" || verify "chart labels differ or OUD pods are missing"':
        '''if [[ "$pods" -gt 0 ]]; then
  pass "found OUD-labelled pods"
else
  verify "chart labels differ or OUD pods are missing"
fi''',
    },
}

for filename, changes in replacements.items():
    path = validation / filename
    text = path.read_text(encoding="utf-8")
    for old, new in changes.items():
        if old not in text:
            raise SystemExit(f"Expected ShellCheck target not found in {path}: {old}")
        text = text.replace(old, new)
    path.write_text(text, encoding="utf-8")

for path in validation.glob("validate-*.sh"):
    text = path.read_text(encoding="utf-8")
    path.write_text(
        "\n".join(line.rstrip() for line in text.splitlines()) + "\n",
        encoding="utf-8",
    )

print("Validation scripts refactored for SC1091 and SC2015.")
