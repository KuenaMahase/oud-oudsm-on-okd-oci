#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
cd "$root"

marker='## Historical artifacts and work evidence'
if ! grep -Fq "$marker" README.md; then
  cat >> README.md <<'EOF'

## Historical artifacts and work evidence

- [Complete implementation history](docs/20-complete-implementation-history.md)
- [Presentation transcript](docs/21-presentation-transcript.md)
- [Work evidence gallery](docs/22-work-evidence-gallery.md)
- [Source artifact register](docs/23-source-artifact-register.md)
- [Sanitized PowerPoint deck](artifacts/presentation/OUD-Implementation-on-OKD-on-OCI-sanitized.pptx)
- [Sanitized PDF deck](artifacts/presentation/OUD-Implementation-on-OKD-on-OCI-sanitized.pdf)

The raw screenshot archive and access-bearing source files remain offline.
All 130 screenshots are represented through sanitized thumbnails, contact
sheets, filenames, and SHA-256 hashes.
EOF
fi

printf 'Expansion navigation added. Review with: git diff -- README.md\n'
