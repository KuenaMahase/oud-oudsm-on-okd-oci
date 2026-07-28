#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
mkdir -p "$root/diagrams/rendered/svg"

for source in "$root"/diagrams/mermaid/*.mmd; do
  name=$(basename "$source" .mmd)
  npx -y @mermaid-js/mermaid-cli \
    -i "$source" \
    -o "$root/diagrams/rendered/svg/$name.svg" \
    --backgroundColor transparent
  printf 'Rendered %s\n' "$name"
done
