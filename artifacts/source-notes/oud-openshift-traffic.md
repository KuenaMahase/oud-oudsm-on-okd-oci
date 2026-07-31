# Historical source note

> Sanitized working note. Treat commands and values as historical evidence, not a current production runbook.

OUD OpenShift Traffic Flow Architecture
Complete Traffic Flow Path
External Client (LDAP/LDAPS)
         ↓
OpenShift Router/HAProxy
         ↓
OpenShift Route (oud-ldap-route / oud-ldaps-route)
         ↓
OUD Proxy Service (oud-proxy-service)
         ↓
OUD Proxy Pod (Load Balancer - Round Robin/Fewest Operations)
         ↓
OUD Directory Service (oud-directory-service)
         ↓
OUD Directory Server Pod (Actual Data)

Layer-by-Layer Breakdown
1. OpenShift Router Layer

Component: OpenShift HAProxy Router
Function: External ingress point, SSL termination (for LDAPS), load balancing
Configuration: Configured via Routes

2. Route Configuration

# LDAP Route (Non-SSL)
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: oud-ldap-route
spec:
  host: oud-ldap.apps.your-cluster.com
  to:
    kind: Service
    name: oud-proxy-service
  port:
    targetPort: ldap  # Port 1389

# LDAPS Route (SSL Passthrough)
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: oud-ldaps-route
spec:
  host: oud-ldaps.apps.your-cluster.com
  to:
    kind: Service
    name: oud-proxy-service
  port:
    targetPort: ldaps  # Port 1636
  tls:
    termination: passthrough  # SSL handled by OUD Proxy

 3. Proxy Service Layer
 apiVersion: v1
kind: Service
metadata:
  name: oud-proxy-service
spec:
  type: ClusterIP
  ports:
  - port: 1389
    targetPort: 1389
    name: ldap
  - port: 1636
    targetPort: 1636
    name: ldaps
  selector:
    app: oud-proxy  # Routes to Proxy Pods

 4. OUD Proxy Pod Layer

Function: LDAP/LDAPS protocol proxy and load balancer
Load Balancing Algorithm: Round-robin or fewest-operations
Configuration: Proxy knows about all directory server endpoints
High Availability: Multiple proxy replicas (3 in our config)

5. Directory Service Layer
apiVersion: v1
kind: Service
metadata:
  name: oud-directory-service
spec:
  type: ClusterIP
  ports:
  - port: 1389
    targetPort: 1389
    name: ldap
  - port: 1636
    targetPort: 1636
    name: ldaps
  selector:
    app: oud-directory  # Routes to Directory Pods

 6. OUD Directory Server Pods

Function: Actual LDAP data storage and processing
Replication: Multi-master replication between instances
Storage: Persistent volumes for data persistence

Detailed Traffic Flow Examples
LDAP Query Flow

1. Client: ldapsearch -h oud-ldap.apps.cluster.com -p 1389 -b "dc=example,dc=com"
2. OpenShift Router: Routes request to oud-proxy-service:1389
3. Kubernetes Service: Load balances to available oud-proxy pod
4. OUD Proxy Pod: Receives LDAP request, selects directory server
5. OUD Proxy Pod: Forwards request to oud-directory-servers-X:1389
6. OUD Directory Pod: Processes query, returns results
7. Response flows back through proxy to client

LDAPS (Secure) Query Flow

1. Client: ldapsearch -h oud-ldaps.apps.cluster.com -p 1636 -Z
2. OpenShift Router: SSL passthrough to oud-proxy-service:1636
3. OUD Proxy Pod: Handles SSL/TLS termination and LDAP processing
4. OUD Proxy Pod: May use SSL/TLS to communicate with directory servers
5. Response encrypted and sent back to client

Service Discovery and Load Balancing
Proxy to Directory Server Communication
# Internal service discovery within cluster
# Proxy pods connect to directory servers via:
oud-directory-servers-0.oud-directory-headless.oud-cluster.svc.cluster.local:1389
oud-directory-servers-1.oud-directory-headless.oud-cluster.svc.cluster.local:1389
oud-directory-servers-2.oud-directory-headless.oud-cluster.svc.cluster.local:1389
oud-directory-servers-3.oud-directory-headless.oud-cluster.svc.cluster.local:1389

Headless Service for Directory Servers
apiVersion: v1
kind: Service
metadata:
  name: oud-directory-headless
spec:
  clusterIP: None  # Headless service
  ports:
  - port: 1389
    name: ldap
  - port: 1636
    name: ldaps
  selector:
    app: oud-directory

Load Balancing Strategies
1. OpenShift Router Level

Round-robin between proxy pods
Session affinity (if configured)
Health check based routing

2. OUD Proxy Level

Round-robin: Equal distribution across directory servers
Fewest-operations: Route to least busy directory server
Health-based: Avoid failed directory servers

3. Kubernetes Service Level

Built-in load balancing between proxy replicas
Automatic failover for unhealthy pods

High Availability Features
Router Layer HA

Multiple OpenShift router replicas
Automatic failover to healthy routers
External load balancer integration

Proxy Layer HA

Multiple proxy pod replicas (3 in config)
Pod anti-affinity across nodes
Horizontal Pod Autoscaler based on load

Directory Layer HA

Multi-master replication
Pod anti-affinity across nodes
Persistent storage with replication

Monitoring and Troubleshooting
Connection Monitoring

# Check route status
oc get routes -n oud-cluster

# Check service endpoints
oc get endpoints -n oud-cluster

# Check proxy pod logs
oc logs -f deployment/oud-proxy-servers -n oud-cluster

# Check directory server logs
oc logs -f oud-directory-servers-0 -n oud-cluster

# Test connectivity
oc exec -it oud-proxy-servers-xxx -- ldapsearch -h oud-directory-servers-0 -p 1389 -b "dc=example,dc=com"

Network Policies

# Allow traffic flow between components
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: oud-network-policy
spec:
  podSelector:
    matchLabels:
      app: oud-directory
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: oud-proxy  # Proxy can reach directory servers
    ports:
    - protocol: TCP
      port: 1389
    - protocol: TCP
      port: 1636

Performance Optimization
Connection Pooling

Proxy maintains connection pools to directory servers
Reduces connection overhead for frequent queries
Configurable pool sizes based on load

Caching Strategy

Proxy-level caching for frequent queries
Directory server entry caching
Negative cache for failed lookups

SSL/TLS Optimization

SSL session reuse
Cipher suite optimization
Certificate caching

This architecture ensures that LDAP/LDAPS traffic flows efficiently from external clients through the OpenShift infrastructure to the appropriate OUD directory servers while maintaining high availability, security, and performance.

