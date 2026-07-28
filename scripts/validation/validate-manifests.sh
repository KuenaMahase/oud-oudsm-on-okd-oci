#!/usr/bin/env bash
set -euo pipefail

if command -v yamllint >/dev/null 2>&1; then
  yamllint manifests helm
else
  printf 'SKIPPED: yamllint is not installed\n'
fi

python3 - <<'PY_CHECK'
from pathlib import Path
try:
    import yaml
except ImportError:
    print('SKIPPED: PyYAML is not installed')
    raise SystemExit(0)
for p in list(Path('manifests').rglob('*.yaml')) + list(Path('helm').rglob('*.yaml')):
    with p.open(encoding='utf-8') as f:
        list(yaml.safe_load_all(f))
    print(f'PASS: parsed {p}')
PY_CHECK
