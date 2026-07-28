# OUDSM Helm deployment

## Successful sequence

OUDSM was prepared with a dedicated service account and PVC. The safe initialization pattern was:

```text
replicaCount 1
-> wait for first WebLogic domain creation
-> validate the OUDSM UI and persisted domain
-> scale to 2 replicas
```

Starting multiple replicas before initial domain creation can cause competing initialization against shared storage.

## Sanitized deployment commands

```bash
oc new-project oudsmns
oc create serviceaccount oudsm-sa -n oudsmns
oc adm policy add-scc-to-user anyuid -z oudsm-sa -n oudsmns

oc apply -f manifests/oudsm/oudsm-pvc.example.yaml
helm show values <path-to-oudsm-chart> > /tmp/oudsm-default-values.yaml
helm lint <path-to-oudsm-chart> -f helm/oudsm/values.example.yaml
helm template oudsm <path-to-oudsm-chart>   -n oudsmns -f helm/oudsm/values.example.yaml > /tmp/oudsm-rendered.yaml
oc apply --dry-run=server -f /tmp/oudsm-rendered.yaml

helm upgrade --install oudsm <path-to-oudsm-chart>   -n oudsmns -f helm/oudsm/values.example.yaml   --wait --timeout 30m
```

## First-start checks

```bash
oc get pods,svc,pvc -n oudsmns -o wide
oc get events -n oudsmns --sort-by=.lastTimestamp | tail -100
oc logs -n oudsmns deployment/<oudsm-deployment> --all-containers --tail=200
oc wait --for=condition=Available deployment/<oudsm-deployment>   -n oudsmns --timeout=30m
```

## Scale-out

```bash
# Prefer Helm so desired state remains in the release values.
helm upgrade oudsm <path-to-oudsm-chart>   -n oudsmns -f helm/oudsm/values.example.yaml   --set replicaCount=2 --wait --timeout 20m
```

## Route verification

```bash
oc get route -n oudsmns -o wide
oc get route -n oudsmns <route-name> -o yaml
oc get svc -n oudsmns <service-name> -o yaml
oc get endpointslices -n oudsmns
curl -kI "https://<sanitized-route-host>/oudsm/"
```

The exact historical PVC capacity and Route target are retained as `VERIFY` because conflicting notes exist.

## Official references

- Oracle OUDSM Kubernetes documentation: <https://docs.oracle.com/en/middleware/idm/unified-directory/14.1.2/osmku/>
- OUDSM Helm chart parameters: <https://docs.oracle.com/en/middleware/idm/unified-directory/14.1.2/osmku/configuration-parameters-oudsm-helm-chart.html>
- OpenShift Routes: <https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/ingress_and_load_balancing/routes>
