# Verify register

| ID | Unresolved fact | Why unresolved | Evidence that will close it |
|---|---|---|---|
| V-001 | Exact OUD chart commit/tag | Values file does not preserve chart metadata | `helm get metadata`, chart archive, or Git commit used |
| V-002 | Exact OUD image digest | Tag recovered, digest not retained | `oc get pod -o jsonpath` imageID or registry evidence |
| V-003 | Final OUDSM PVC capacity | Notes conflict between 5, 10 and 20 GiB | Final PVC YAML or `oc get pvc` output |
| V-004 | OUDSM Route target and TLS details | Re-encrypt remembered, live YAML absent | `oc get route -n oudsmns <name> -o yaml` |
| V-005 | OUDSM final replica count | Sequence says 1 then 2; final output not retained in parsed evidence | Deployment YAML or pod listing after scale |
| V-006 | Proxy network-group workflow attachment | Remediation commands exist; final successful output truncated | `get-network-group-prop` output from both proxies |
| V-007 | Final LDAPS listener and NodePort | Remembered 636/30636 not yet observed | OCI listener/backend export and Service YAML |
| V-008 | ELK deployment status | Namespace and planning exist; runtime proof is unclear | `oc get pods -n elkns` and application evidence |
