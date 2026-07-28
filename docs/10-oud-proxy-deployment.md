# OUD Proxy deployment and routing

## Observed successful state

- Two OUD Proxy pods: `oud-proxy-0` and `oud-proxy-1`.
- LDAP public NodePort Service: service port `389`, node port `30089`.
- Three LDAP server extensions pointing to three stable OUD service DNS names on port `1389`.
- Three `proxy-ldap` workflow elements.
- One `load-balancing` workflow element named `lb-we`.
- A proportional algorithm with equal operation weights.

## Configuration model

```text
LDAP listener
-> network group
-> base-DN workflow
-> lb-we
-> proportional route
-> proxy-we-dsN
-> LDAP server extension dsN
-> selected OUD DS endpoint
```

The final network-group attachment output has not yet been recovered and remains `VERIFY`. The diagram therefore uses a dashed node for that connection.

## Safe inspection commands

```bash
oc get pods -n oudns -l app.kubernetes.io/name=oud-proxy -o wide
oc get svc -n oudns
oc describe svc -n oudns oud-proxy-ldap-public

# Create the password file inside the container without echoing the password.
oc exec -it -n oudns oud-proxy-0 -- bash
read -rsp 'Directory Manager password: ' PWD; echo
printf '%s' "$PWD" > /tmp/oud-password
chmod 600 /tmp/oud-password
unset PWD

DS=/u01/oracle/oud/bin/dsconfig
"$DS" -h localhost -p 1444 -D 'cn=Directory Manager'   -j /tmp/oud-password -X -n list-extensions
"$DS" -h localhost -p 1444 -D 'cn=Directory Manager'   -j /tmp/oud-password -X -n list-workflow-elements
"$DS" -h localhost -p 1444 -D 'cn=Directory Manager'   -j /tmp/oud-password -X -n list-workflows
"$DS" -h localhost -p 1444 -D 'cn=Directory Manager'   -j /tmp/oud-password -X -n list-network-groups
rm -f /tmp/oud-password
```

## Useful connectivity commands

```bash
# Resolve all internal endpoints from the proxy pod.
oc exec -n oudns oud-proxy-0 -- getent hosts   oud-ds-rs-ldap-0.oudns.svc.cluster.local

# Test an anonymous root-DSE query to each DS.
for i in 0 1 2; do
  oc exec -n oudns oud-proxy-0 -- ldapsearch -x     -H "ldap://oud-ds-rs-ldap-${i}.oudns.svc.cluster.local:1389"     -s base -b '' namingContexts
done
```

## Official references

- Oracle OUD administration documentation: <https://docs.oracle.com/en/middleware/idm/unified-directory/14.1.2/oudag/>
- Oracle OUD Kubernetes documentation: <https://docs.oracle.com/en/middleware/idm/unified-directory/14.1.2/oudku/>
- Kubernetes Services: <https://kubernetes.io/docs/concepts/services-networking/service/>
