# Contributing

1. Work on a branch.
2. Preserve the successful-deployment-only rule.
3. Add evidence and an official reference for material technical claims.
4. Mark unresolved items `VERIFY`.
5. Never add confidential original artifacts.
6. Run the local checks before opening a pull request.

```bash
git diff --check
bash scripts/security/scan-sensitive-data.sh
bash scripts/validation/validate-manifests.sh
```
