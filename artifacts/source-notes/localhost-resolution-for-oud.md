# Historical source note

> Sanitized working note. Treat commands and values as historical evidence, not a current production runbook.

<public-ldap-lb-ip> api.example.internal
<public-ldap-lb-ip> oauth-openshift.apps.example.internal
<public-ldap-lb-ip> console-openshift-console.apps.example.internal
<public-ldap-lb-ip> grafana-openshift-monitoring.apps.example.internal
<public-ldap-lb-ip> thanos-querier-openshift-monitoring.apps.example.internal
<public-ldap-lb-ip> prometheus-k8s-openshift-monitoring.apps.example.internal
<public-ldap-lb-ip> alertmanager-main-openshift-monitoring.apps.example.internal
<public-ldap-lb-ip> downloads-openshift-console.apps.example.internal

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Username:
kubeadmin
Password:
SuFPu-cw5rY-T7UVk-Dtfb5

Your API token is
<REDACTED_TOKEN>
Log in with this token

oc login --token=<REDACTED_TOKEN> --server=https://api.example.internal:6443

Use this token directly against the API

curl -H "Authorization: Bearer <REDACTED_TOKEN>" "https://api.example.internal:6443/apis/user.openshift.io/v1/users/~"



