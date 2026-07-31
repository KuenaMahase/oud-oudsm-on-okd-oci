#!/usr/bin/env python3
"""Generate a GitHub-renderable Mermaid gallery from authoritative .mmd files.

Also refreshes the diagram blocks embedded in README.md so the landing page
cannot drift from the .mmd sources. CI runs this and then fails on
`git diff --exit-code`, which makes both outputs enforced rather than
hand-maintained.
"""
import re
from pathlib import Path

root = Path(__file__).resolve().parents[2]
src_dir = root / "diagrams" / "mermaid"
out = root / "diagrams" / "GALLERY.md"
readme = root / "README.md"

titles = {
    "01-final-platform-context": "1. Final platform context",
    "02-final-oci-network-topology": "2. OCI network topology",
    "03-final-okd-cluster-topology": "3. OKD/OpenShift cluster topology",
    "04-final-load-balancer-and-ingress-flow": "4. Load-balancer and ingress flows",
    "05-final-nfs-csi-storage-flow": "5. NFS CSI storage flow",
    "06-final-oud-statefulset-storage": "6. OUD StatefulSet and storage",
    "07-final-oud-replication-topology": "7. OUD replication topology",
    "08-final-oud-proxy-routing": "8. OUD Proxy routing",
    "09-final-oudsm-access-flow": "9. OUDSM access flow",
    "10-final-deployment-sequence": "10. Successful deployment sequence",
    "11-final-nfs-failure-recovery": "11. NFS failure recovery",
    "12-final-security-trust-boundaries": "12. Security trust boundaries",
}

parts = [
    "# Mermaid architecture gallery\n",
    "This page is generated from `diagrams/mermaid/*.mmd`. Edit the `.mmd` source and run `python3 scripts/rendering/build-mermaid-gallery.py`; do not edit generated diagram blocks by hand.\n",
    "> Solid paths are verified or strongly observed. Dashed or explicitly labelled `VERIFY` paths remain unresolved.\n",
]
for source in sorted(src_dir.glob("*.mmd")):
    stem = source.stem
    parts.append(f"## {titles.get(stem, stem)}\n")
    parts.append(f"Source: [`mermaid/{source.name}`](mermaid/{source.name})\n")
    parts.append("```mermaid\n" + source.read_text(encoding="utf-8").rstrip() + "\n```\n")

out.write_text("\n".join(parts), encoding="utf-8")
print(out)

# README.md embeds a subset of the same diagrams between marker comments:
#   <!-- BEGIN GENERATED: 01-final-platform-context -->
#   <!-- END GENERATED: 01-final-platform-context -->
# Every marked block is rewritten from its .mmd source.
block_re = re.compile(
    r"(<!-- BEGIN GENERATED: (?P<stem>[\w-]+) -->\n).*?(?=<!-- END GENERATED: (?P=stem) -->)",
    re.DOTALL,
)


def replace(match):
    stem = match.group("stem")
    source = src_dir / f"{stem}.mmd"
    if not source.is_file():
        raise SystemExit(f"README references unknown diagram source: {source}")
    body = source.read_text(encoding="utf-8").rstrip()
    return f"{match.group(1)}\n```mermaid\n{body}\n```\n\n"


text = readme.read_text(encoding="utf-8")
rendered, count = block_re.subn(replace, text)
if not count:
    raise SystemExit("README.md contains no BEGIN GENERATED diagram markers")
readme.write_text(rendered, encoding="utf-8")
print(f"{readme} ({count} diagram blocks)")
