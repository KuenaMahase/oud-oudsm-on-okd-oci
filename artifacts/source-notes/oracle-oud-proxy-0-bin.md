# Historical source note

> Sanitized working note. Treat commands and values as historical evidence, not a current production runbook.

[oracle@oud-proxy-0 bin]$ ls
backup		  dbtest   dsconfig	     dsreplication    export-ldif  import-ldif	ldapmodify	    ldif-diff	list-backends	manage-suffix  oudExtractMovePlan  rebuild-index	 split-ldif  stop-ds
base64		  dps2oud  dsframework	     dstune	      gicadm	   ldapcompare	ldappasswordmodify  ldifmodify	make-ldif	manage-tasks   oudPasteConfig	   restore		 start-ds    upgrade-oud-instances
create-rc-script  ds2oud   dsjavaproperties  encode-password  gicdump	   ldapdelete	ldapsearch	    ldifsearch	manage-account	oudCopyConfig  purge-backup	   setup-oracle-context  status      verify-index
[oracle@oud-proxy-0 bin]$ ls -l
total 176
-rwxr-x---. 1 oracle root 1422 Feb 18  2025 backup
-rwxr-x---. 1 oracle root 1393 Feb 18  2025 base64
-rwxr-x---. 1 oracle root 1412 Feb 18  2025 create-rc-script
-rwxr-x---. 1 oracle root 1416 Feb 18  2025 dbtest
-rwxr-x---. 1 oracle root  527 Feb 18  2025 dps2oud
-rwxr-x---. 1 oracle root  518 Feb 18  2025 ds2oud
-rwxr-x---. 1 oracle root 1434 Feb 18  2025 dsconfig
-rwxr-x---. 1 oracle root 1463 Feb 18  2025 dsframework
-rwxr-x---. 1 oracle root 1465 Feb 18  2025 dsjavaproperties
-rwxr-x---. 1 oracle root 1992 Feb 18  2025 dsreplication
-rwxr-x---. 1 oracle root  490 Feb 18  2025 dstune
-rwxr-x---. 1 oracle root 1503 Feb 18  2025 encode-password
-rwxr-x---. 1 oracle root 1487 Feb 18  2025 export-ldif
-rwxr-x---. 1 oracle root  508 Feb 18  2025 gicadm
-rwxr-x---. 1 oracle root  523 Feb 18  2025 gicdump
-rwxr-x---. 1 oracle root 1480 Feb 18  2025 import-ldif
-rwxr-x---. 1 oracle root 1416 Feb 18  2025 ldapcompare
-rwxr-x---. 1 oracle root 1413 Feb 18  2025 ldapdelete
-rwxr-x---. 1 oracle root 1443 Feb 18  2025 ldapmodify
-rwxr-x---. 1 oracle root 1438 Feb 18  2025 ldappasswordmodify
-rwxr-x---. 1 oracle root 1413 Feb 18  2025 ldapsearch
-rwxr-x---. 1 oracle root 1418 Feb 18  2025 ldif-diff
-rwxr-x---. 1 oracle root 1417 Feb 18  2025 ldifmodify
-rwxr-x---. 1 oracle root 1415 Feb 18  2025 ldifsearch
-rwxr-x---. 1 oracle root 1435 Feb 18  2025 list-backends
-rwxr-x---. 1 oracle root 1671 Feb 18  2025 make-ldif
-rwxr-x---. 1 oracle root 1420 Feb 18  2025 manage-account
-rwxr-x---. 1 oracle root  507 Feb 18  2025 manage-suffix
-rwxr-x---. 1 oracle root 1422 Feb 18  2025 manage-tasks
-rwxr-x---. 1 oracle root 2208 Feb 18  2025 oudCopyConfig
-rwxr-x---. 1 oracle root 2248 Feb 18  2025 oudExtractMovePlan
-rwxr-x---. 1 oracle root 2194 Feb 18  2025 oudPasteConfig
-rwxr-x---. 1 oracle root 1407 Feb 18  2025 purge-backup
-rwxr-x---. 1 oracle root 1537 Feb 18  2025 rebuild-index
-rwxr-x---. 1 oracle root 1425 Feb 18  2025 restore
-rwxr-x---. 1 oracle root  569 Feb 18  2025 setup-oracle-context
-rwxr-x---. 1 oracle root  583 Feb 18  2025 split-ldif
-rwxr-x---. 1 oracle root 6140 Feb 18  2025 start-ds
-rwxr-x---. 1 oracle root 1404 Feb 18  2025 status
-rwxr-x---. 1 oracle root 7200 Feb 18  2025 stop-ds
-rwxr-x---. 1 oracle root 1258 Feb 18  2025 upgrade-oud-instances
-rwxr-x---. 1 oracle root 1668 Feb 18  2025 verify-index
[oracle@oud-proxy-0 bin]$ PWF=/tmp/oudpw.txt
printf %s "$rootUserPassword" > "$PWF"; chmod 600 "$PWF"
DS=/u01/oracle/oud/bin/dsconfig
ADM=1444
BDN="cn=Directory Manager"
[oracle@oud-proxy-0 bin]$ $DS -h localhost -p $ADM -D "$BDN" -j "$PWF" -X -n list-workflow-elements
Workflow Element : Type               : enabled
-----------------:--------------------:--------
adminRoot        : ldif-local-backend : true
virtualAcis      : db-local-backend   : true

proxy-ldap workflow element: the actual connector from the proxy to one DS (e.g., proxy-we-ds1 → oud-ds-rs-ldap-1:1389).
load-balancing workflow element (lb-we): the chooser. For every client request hitting oud-proxy-svc:1389/1636, it picks a route.
algorithm: the policy the chooser uses (e.g., proportional for even spread, failover for primary→secondary, etc.).
routes: the entries under lb-we that point to each proxy-ldap (and carry weights/priorities depending on the algorithm).

operator@workstation:~$ oc -n oudns exec -it oud-proxy-1 -- bash
[oracle@oud-proxy-1 oracle]$ PWF=/tmp/pwd-file; printf %s "$rootUserPassword" > "$PWF"
DS=/u01/oracle/oud/bin/dsconfig
ADM=1444
BDN="cn=Directory Manager"
[oracle@oud-proxy-1 oracle]$ $DS -h localhost -p $ADM -D "$BDN" -j "$PWF" -X -n create-extension \
  --extension-name ds0 --type ldap-server \
  --set enabled:true \
  --set remote-ldap-server-address:oud-ds-rs-ldap-0.oudns.svc.cluster.local \
  --set remote-ldap-server-port:1389

$DS -h localhost -p $ADM -D "$BDN" -j "$PWF" -X -n create-extension \
  --extension-name ds1 --type ldap-server \
  --set enabled:true \
  --set remote-ldap-server-address:oud-ds-rs-ldap-1.oudns.svc.cluster.local \
  --set remote-ldap-server-port:1389

$DS -h localhost -p $ADM -D "$BDN" -j "$PWF" -X -n create-extension \
  --extension-name ds2 --type ldap-server \
  --set enabled:true \
  --set remote-ldap-server-address:oud-ds-rs-ldap-2.oudns.svc.cluster.local \
  --set remote-ldap-server-port:1389
[oracle@oud-proxy-1 oracle]$ $DS -h localhost -p $ADM -D "$BDN" -j "$PWF" -X -n create-workflow-element \
  --element-name proxy-we-ds0 --type proxy-ldap \
  --set enabled:true \
  --set client-cred-mode:use-client-identity \
  --set ldap-server-extension:ds0

$DS -h localhost -p $ADM -D "$BDN" -j "$PWF" -X -n create-workflow-element \
  --element-name proxy-we-ds1 --type proxy-ldap \
  --set enabled:true \
  --set client-cred-mode:use-client-identity \
  --set ldap-server-extension:ds1

$DS -h localhost -p $ADM -D "$BDN" -j "$PWF" -X -n create-workflow-element \
  --element-name proxy-we-ds2 --type proxy-ldap \
  --set enabled:true \
  --set client-cred-mode:use-client-identity \
  --set ldap-server-extension:ds2
[oracle@oud-proxy-1 oracle]$ $DS -h localhost -p $ADM -D "$BDN" -j "$PWF" -X -n create-workflow-element \
  --element-name lb-we --type load-balancing --set enabled:true
[oracle@oud-proxy-1 oracle]$ $DS -h localhost -p $ADM -D "$BDN" -j "$PWF" -X -n create-load-balancing-algorithm \
  --element-name lb-we --type proportional
[oracle@oud-proxy-1 oracle]$ $DS -h localhost -p $ADM -D "$BDN" -j "$PWF" -X -n create-load-balancing-route \
  --element-name lb-we --route-name lb-ds0 --type proportional \
  --set workflow-element:proxy-we-ds0 \
  --set add-weight:1 --set bind-weight:1 --set compare-weight:1 \
  --set delete-weight:1 --set extended-weight:1 --set modify-weight:1 \
  --set modifydn-weight:1 --set search-weight:1

$DS -h localhost -p $ADM -D "$BDN" -j "$PWF" -X -n create-load-balancing-route \
  --element-name lb-we --route-name lb-ds1 --type proportional \
  --set workflow-element:proxy-we-ds1 \
  --set add-weight:1 --set bind-weight:1 --set compare-weight:1 \
  --set delete-weight:1 --set extended-weight:1 --set modify-weight:1 \
  --set modifydn-weight:1 --set search-weight:1

$DS -h localhost -p $ADM -D "$BDN" -j "$PWF" -X -n create-load-balancing-route \
  --element-name lb-we --route-name lb-ds2 --type proportional \
  --set workflow-element:proxy-we-ds2 \
  --set add-weight:1 --set bind-weight:1 --set compare-weight:1 \
  --set delete-weight:1 --set extended-weight:1 --set modify-weight:1 \
  --set modifydn-weight:1 --set search-weight:1
[oracle@oud-proxy-1 oracle]$ # Show extensions (look for Type: ldap-server)
$DS -h localhost -p 1444 -D "$BDN" -j "$PWF" -X -n list-extensions

# Inspect one extension
$DS -h localhost -p 1444 -D "$BDN" -j "$PWF" -X -n get-extension-prop \
  --extension-name ds0

# Show all workflow elements (you should now see proxy-ldap and load-balancing)
$DS -h localhost -p 1444 -D "$BDN" -j "$PWF" -X -n list-workflow-elements
Extension                      : Type
-------------------------------:-------------------------------
Directory Integration Platform : directory-integration-platform
ds0                            : ldap-server
ds1                            : ldap-server
ds2                            : ldap-server
REST Server                    : rest-server
REST Web Services Provider     : rest-web-service
Property                   : Value(s)
---------------------------:-----------------------------------------
directory-type             : oud
enabled                    : true
page-size                  : 0
remote-ldap-server-address : oud-ds-rs-ldap-0.oudns.svc.cluster.local
remote-ldap-server-port    : 1389
ssl-cipher-suite           : -
ssl-protocol               : -
Workflow Element : Type               : enabled
-----------------:--------------------:--------
adminRoot        : ldif-local-backend : true
lb-we            : load-balancing     : true
proxy-we-ds0     : proxy-ldap         : true
proxy-we-ds1     : proxy-ldap         : true
proxy-we-ds2     : proxy-ldap         : true
virtualAcis      : db-local-backend   : true
[oracle@oud-proxy-1 oracle]$


Right now your proxy has:

proxy-ldap workflow elements: proxy-we-ds0/ds1/ds2 (each points to one DS: oud-ds-rs-ldap-{0,1,2}:1389)

a load-balancing workflow element: lb-we (algorithm = proportional, routes lb-ds0/ds1/ds2 → the three proxy-we-*)

…but it’s missing a workflow mapping that says: “for base-DN o=maserutel, send traffic to lb-we”. Without that mapping, the proxy accepts your bind, then can’t locate a workflow for that base DN and returns 32.

Your DS pods do have the suffix (you showed o=maserutel … Replication Ongoing), so we just need to register it on the proxies.

Great—your last run tells us exactly what’s missing:

* The LDAP listener (1389) is **up**.
* OUD Proxy **doesn’t** attach a “network-group” via a `network-group` property on the handler (that property isn’t used here).
* You **do** have a network group named `network-group` (not `default-network-group`).
* Your workflow `MaseruTel-wf` is correct (`base-dn: o=maserutel → workflow-element: lb-we`), but the **network group isn’t pointing at that workflow** yet.

Fix = add the workflow to the existing network group, on **both** proxy pods.

---

## 1) Attach `MaseruTel-wf` to the network group

Run on each proxy pod (0 **and** 1). This tries both possible property names (`workflow` vs `workflows`)—one will succeed:

```bash
# Proxy 0
oc -n oudns exec -it oud-proxy-0 -- bash -lc '
PF=/tmp/pf; printf 1234 >"$PF"
DS=/u01/oracle/oud/bin/dsconfig
ADM=1444
BDN="cn=Directory Manager"

echo "Network groups:"
$DS -h localhost -p $ADM -D "$BDN" -j "$PF" -X -n list-network-groups

# Inspect the existing group
NG="network-group"
echo "---- current props of $NG ----"
$DS -h localhost -p $ADM -D "$BDN" -j "$PF" -X -n get-network-group-prop --group-name "$NG"

# Add the workflow (one of these two lines will be accepted)
$DS -h localhost -p $ADM -D "$BDN" -j "$PF" -X -n set-network-group-prop --group-name "$NG" --add workflow:MaseruTel-wf || \
$DS -h localhost -p $ADM -D "$BDN" -j "$PF" -X -n set-network-group-prop --group-name "$NG" --add workflows:MaseruTel-wf

echo "---- re-check props of $NG ----"
$DS -h localhost -p $ADM -D "$BDN" -j "$PF" -X -n get-network-group-prop --group-name "$NG"

rm -f "$PF"
'

# Proxy 1
oc -n oudns exec -it oud-proxy-1 -- bash -lc '
PF=/tmp/pf; printf 1234 >"$PF"
DS=/u01/oracle/oud/bin/dsconfig
ADM=1444
BDN="cn=Directory Manager"
NG="network-group"

$DS -h localhost -p $ADM -D "$BDN" -j "$PF" -X -n set-network-group-prop --group-name "$NG" --add workflow:MaseruTel-wf || \
$DS -h localhost -p $ADM -D "$BDN" -j "$PF" -X -n set-network-group-prop --group-name "$NG" --add workflows:MaseruTel-wf

$DS -h localhost -p $ADM -D "$BDN" -j "$PF" -X -n get-network-group-prop --group-name "$NG"
rm -f "$PF"
'
```

If it complains about the property name, paste the error and run:

```bash
dsconfig -h localhost -p 1444 -D "cn=Directory Manager" -j /tmp/pf -X -n \
  get-network-group-prop --group-name network-group --advanced
```

to see the exact property label, then use that.

---

## 2) Test from inside each proxy (OUD’s ldapsearch syntax—no “-x”, no “-LLL”)

```bash
oc -n oudns exec -it oud-proxy-0 -- /u01/oracle/oud/bin/ldapsearch \
  -h 127.0.0.1 -p 1389 \
  -D "cn=Directory Manager" -w "1234" \
  -b "o=maserutel" -s base "(objectClass=*)" dn objectClass o

oc -n oudns exec -it oud-proxy-1 -- /u01/oracle/oud/bin/ldapsearch \
  -h 127.0.0.1 -p 1389 \
  -D "cn=Directory Manager" -w "1234" \
  -b "o=maserutel" -s base "(objectClass=*)" dn objectClass o
```

Expected: both return the `o=maserutel` entry (DN + objectClass).

> Seeing an empty `namingContexts` on the proxy root DSE is fine for OUD Proxy; it doesn’t list DS suffixes there. The important test is that a **base** search under `o=maserutel` works.

---

## 3) Test end-to-end from your laptop (OpenLDAP client)

You already have the public LB and DNS working for 389 → proxy → DS. Now verify `o=maserutel` through the same path:

```bash
ldapsearch -x -H ldap://ldap.local.com:389 \
  -D "cn=Directory Manager" -w "1234" \
  -b "o=maserutel" -s base -LLL "(objectClass=*)" dn objectClass o
```

If that returns the entry, your flow is confirmed:

**Client → NLB public IP:389 → `oud-proxy-ldap-public` Service → proxy pod :1389 → `lb-we` (proportional) → DS pods :1389.**

---

### Why this is the fix (based on your outputs)
Fix (add the workflow on both proxy pods)
for p in 0 1; do
  oc -n oudns exec -it oud-proxy-$p -- bash -lc '
    printf "1234" >/tmp/pf
    DS=/u01/oracle/oud/bin/dsconfig
    ADM=1444
    BDN="cn=Directory Manager"

    # Show existing workflows (you’ll likely only see adminRoot / virtualAcis)
    $DS -h localhost -p $ADM -D "$BDN" -j /tmp/pf -X -n list-workflows

    # Create a workflow that maps o=maserutel -> lb-we (ignore "already exists")
    $DS -h localhost -p $ADM -D "$BDN" -j /tmp/pf -X -n create-workflow \
        --workflow-name MaseruTel-wf \
        --set enabled:true \
        --set base-dn:o=maserutel \
        --set workflow-element:lb-we || true

    # Verify the mapping
    $DS -h localhost -p $ADM -D "$BDN" -j /tmp/pf -X -n get-workflow-prop \
        --workflow-name MaseruTel-wf \
        --property base-dn \
        --property workflow-element \
        --property enabled

    rm -f /tmp/pf
  '
done


Attach `MaseruTel-wf` to `network-group` → the 1389 listener now routes searches under `o=maserutel` into the `lb-we` and on to the DS backends.

operator@workstation:~$ # Proxy 0
oc -n oudns exec -it oud-proxy-0 -- bash -lc '
PF=/tmp/pf; printf 1234 >"$PF"
DS=/u01/oracle/oud/bin/dsconfig
ADM=1444
BDN="cn=Directory Manager"

echo "Network groups:"
$DS -h localhost -p $ADM -D "$BDN" -j "$PF" -X -n list-network-groups

# Inspect the existing group
NG="network-group"
echo "---- current props of $NG ----"
$DS -h localhost -p $ADM -D "$BDN" -j "$PF" -X -n get-network-group-prop --group-name "$NG"

# Add the workflow (one of these two lines will be accepted)
$DS -h localhost -p $ADM -D "$BDN" -j "$PF" -X -n set-network-group-prop --group-name "$NG" --add workflow:MaseruTel-wf || \
$DS -h localhost -p $ADM -D "$BDN" -j "$PF" -X -n set-network-group-prop --group-name "$NG" --add workflows:MaseruTel-wf

echo "---- re-check props of $NG ----"
$DS -h localhost -p $ADM -D "$BDN" -j "$PF" -X -n get-network-group-prop --group-name "$NG"

rm -f "$PF"
'

# Proxy 1
oc -n oudns exec -it oud-proxy-1 -- bash -lc '
PF=/tmp/pf; printf 1234 >"$PF"
DS=/u01/oracle/oud/bin/dsconfig
ADM=1444
BDN="cn=Directory Manager"
NG="network-group"

$DS -h localhost -p $ADM -D "$BDN" -j "$PF" -X -n set-network-group-prop --group-name "$NG" --add workflow:MaseruTel-wf || \
$DS -h localhost -p $ADM -D "$BDN" -j "$PF" -X -n set-network-group-prop --group-name "$NG" --add workflows:MaseruTel-wf

$DS -h localhost -p $ADM -D "$BDN" -j "$PF" -X -n get-network-group-prop --group-name "$NG"
rm -f "$PF"
'
Network groups:
Network Group : Type    : enabled : priority : workflow
--------------:---------:---------:----------:---------
network-group : generic : true    : 1        : -
---- current props of network-group ----
Property                           : Value(s)
-----------------------------------:---------
allowed-auth-method                : -
allowed-bind-dn                    : -
allowed-bind-id                    : -
allowed-client                     : -
allowed-port                       : -
allowed-protocol                   : -
certificate-mapper                 : -
denied-client                      : -
enabled                            : true
generic-identity-mapper            : -
gssapi-identity-mapper             : -
is-security-mandatory              : false
priority                           : 1
relocated-rootdse-dn               : ""
relocated-rootdse-workflow-element : -
workflow                           : -
---- re-check props of network-group ----
Property                           : Value(s)
-----------------------------------:-----------
allowed-auth-method                : -
allowed-bind-dn                    : -
allowed-bind-id                    : -
allowed-client                     : -
allowed-port                       : -
allowed-protocol                   : -
certificate-mapper                 : -
denied-client                      : -
enabled                            : true
generic-identity-mapper            : -
gssapi-identity-mapper             : -
is-security-mandatory              : false
priority                           : 1
relocated-rootdse-dn               : ""
relocated-rootdse-workflow-element : -
workflow                           : MaseruTel-wf
Property                           : Value(s)
-----------------------------------:-----------
allowed-auth-method                : -
allowed-bind-dn                    : -
allowed-bind-id                    : -
allowed-client                     : -
allowed-port                       : -
allowed-protocol                   : -
certificate-mapper                 : -
denied-client                      : -
enabled                            : true
generic-identity-mapper            : -
gssapi-identity-mapper             : -
is-security-mandatory              : false
priority                           : 1
relocated-rootdse-dn               : ""
relocated-rootdse-workflow-element : -
workflow                           : MaseruTel-wf
operator@workstation:~$ oc -n oudns exec -it oud-proxy-0 -- /u01/oracle/oud/bin/ldapsearch \
  -h 127.0.0.1 -p 1389 \
  -D "cn=Directory Manager" -w '1234' \
  -b "o=maserutel" -s base "(objectClass=*)" dn objectClass o
dn: o=maserutel
o: MaseruTel
objectClass: organization
objectClass: top

operator@workstation:~$ oc -n oudns exec -it oud-proxy-1 -- /u01/oracle/oud/bin/ldapsearch \
  -h 127.0.0.1 -p 1389 \
  -D "cn=Directory Manager" -w '1234' \
  -b "o=maserutel" -s base "(objectClass=*)" dn objectClass o
dn: o=maserutel
o: MaseruTel
objectClass: organization
objectClass: top

operator@workstation:~$ oc -n oudns exec -it oud-proxy-0 -- /u01/oracle/oud/bin/ldapsearch \
  -h oud-proxy-svc.oudns.svc.cluster.local -p 1389 \
  -D "cn=Directory Manager" -w '1234' \
  -b "o=maserutel" -s base "(objectClass=*)" dn objectClass o
dn: o=maserutel
o: MaseruTel
objectClass: organization
objectClass: top

operator@workstation:~$ ldapsearch -x -H ldap://ldap.local.com:389 \
  -D "cn=Directory Manager" -w '1234' \
  -b "o=maserutel" -s base -LLL "(objectClass=*)" dn objectClass o
dn: o=maserutel
o: MaseruTel
objectClass: organization
objectClass: top

operator@workstation:~$ oc -n oudns exec -it oud-proxy-0 -- bash -lc 'tail -f /u01/oracle/user_projects/oud-proxy-0/OUD/logs/access'
tail: cannot open '/u01/oracle/user_projects/oud-proxy-0/OUD/logs/access' for reading: No such file or directory
tail: no files remaining
command terminated with exit code 1
operator@workstation:~$



