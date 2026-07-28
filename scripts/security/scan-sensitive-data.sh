#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
cd "$root"

patterns=(
  "(?i)vodacom"
  "sha256~[A-Za-z0-9_-]{20,}"
  "(?i)Authorization:[[:space:]]*Bearer[[:space:]]+[A-Za-z0-9._-]{20,}"
  "ocid1\\.[A-Za-z0-9._-]+"
  "-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----"
  "https://[^[:space:]]*objectstorage[^[:space:]]*/p/[A-Za-z0-9_-]{20,}/"
  "(?i)(password|adminPass|rootUserPassword)[[:space:]]*[:=][[:space:]]*[^[:space:]#]{6,}"
  "10\\.0\\.[0-9]{1,3}\\.[0-9]{1,3}"
  "172\\.16\\.130\\.[0-9]{1,3}"
  "84\\.8\\.128\\.140"
  "(?i)oud-oudsm-elk-cluster\\.local\\.com"
  "(?i)privateopc\\.openshiftvcn\\.oraclevcn\\.com"
  "(?i)axzsbkuhurf8"
)

exclude=(
  "--glob=!.git/**"
  "--glob=!.gitignore"
  "--glob=!scripts/security/scan-sensitive-data.sh"
  "--glob=!diagrams/rendered/**"
  "--glob=!evidence/placeholders/**"
)

allow_line='(<[^>]*(password|token)[^>]*>|REPLACE|CHANGE_ME|REDACTED|read -rsp|prompted at runtime|example only)'
failed=0
for pattern in "${patterns[@]}"; do
  matches=$(rg --hidden --line-number --pcre2 "${exclude[@]}" -- "$pattern" . || true)
  if [[ -n "$matches" ]]; then
    filtered=$(printf '%s\n' "$matches" | rg -v --pcre2 "$allow_line" || true)
    if [[ -n "$filtered" ]]; then
      printf '%s\n' "$filtered"
      printf 'Sensitive pattern matched: %s\n' "$pattern" >&2
      failed=1
    fi
  fi
done

# Block sensitive file types even when their contents happen not to match.
while IFS= read -r path; do
  printf 'Blocked sensitive file type: %s\n' "$path" >&2
  failed=1
done < <(find . -path './.git' -prune -o -type f \
  \( -name '*.jks' -o -name '*.p12' -o -name '*.pfx' -o \
     -name '*.kubeconfig' -o -name '*.ldif' -o -name 'boot.properties' \) -print)

if [[ "$failed" -eq 0 ]]; then
  printf 'PASS: no blocked historical identifiers, secrets, or sensitive file types found\n'
else
  printf 'FAIL: review findings before committing or publishing\n' >&2
fi
exit "$failed"
