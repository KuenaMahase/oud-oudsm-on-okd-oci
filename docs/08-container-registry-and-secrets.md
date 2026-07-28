# Container registry and secrets

## Successful implementation

The deployment used Oracle middleware images and private registry pull secrets. Retained values show Oracle OUD and OUDSM CPU image tags and separate secret names. The public repository does not retain the original registry namespace, credentials, or pull-secret JSON.

## Safe creation pattern

```bash
oc create secret docker-registry oracle-registry-secret   --docker-server=container-registry.oracle.com   --docker-username='<oracle-sso-user>'   --docker-password='<token-or-password>'   --docker-email='<email>'   -n oudns

oc secrets link oud-sa oracle-registry-secret --for=pull -n oudns
oc secrets link oudsm-sa oracle-registry-secret --for=pull -n oudsmns
```

## Preflight commands

```bash
oc get secret -n oudns
oc get serviceaccount -n oudns oud-sa -o yaml
oc get serviceaccount -n oudsmns oudsm-sa -o yaml
oc describe pod -n oudns <pod> | sed -n '/Events:/,$p'
```

Apply pull secrets to init containers, Helm hooks, backup jobs, log sidecars, and maintenance jobs—not only the main product container.

## Official references

- Oracle OUD system requirements and registry guidance: <https://docs.oracle.com/en/middleware/idm/unified-directory/14.1.2/oudku/>
- Oracle OUDSM image guidance: <https://docs.oracle.com/en/middleware/idm/unified-directory/14.1.2/osmku/>
- Kubernetes Secrets: <https://kubernetes.io/docs/concepts/configuration/secret/>
