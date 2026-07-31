# Enterprise Deployment Guide Working Draft

> Converted from a historical working `.doc` artifact and sanitized for publication.

```text







                    Enterprise Deployment Guide for Oracle Unified Directory
                    in a Kubernetes Cluster























Contents

                       Purpose     1
                       References  1
                       Definitions, Acronyms and Abbreviations 1

                    Prerequisites  2


                    Capacity Planning   4


                    Prepare NFS    8


                    Prepare OUD/OUDSM Images  9


                    Deploy OUD using Helm     10


                    Deploy OUDSM Pod    11


                    Deploy OUDSM NodePort Service  12


                    Monitor the Pods    13


                    Sample Use Cases    14


                    References     15



Introduction




Purpose


The purpose of this document is to provide product management utilities to
support different tech stack components for deploying Oracle Unified
Directory (OUD) 14c in a Kubernetes cluster, specifically on Red Hat
OpenShift.




References


This document refers to other documents specified in the following table:

|Referred Document         |Reference Description                               |
|Oracle Unified Directory  |Official Oracle documentation for OUD 14c           |
|14c Documentation         |installation and configuration. Available at Oracle |
|                          |Docs.                                               |
|My Oracle Support Doc ID  |Kubernetes and container engine version requirements|
|2723908.1                 |for OUD deployment.                                 |
|OpenShift 4.x             |Official Red Hat OpenShift documentation for cluster|
|Documentation             |setup and Helm usage. Available at OpenShift Docs.  |








Definitions, Acronyms
and Abbreviations

|Term      |Description                                                        |
|OUD       |Oracle Unified Directory, a comprehensive LDAP directory service.  |
|OUDSM     |Oracle Unified Directory Services Manager, a web-based interface   |
|          |for managing OUD.                                                  |
|Kubernetes|An open-source platform for automating containerized applications. |
|OpenShift |Red Hat’s Kubernetes-based platform with additional security and   |
|          |management features.                                               |
|Helm      |A package manager for Kubernetes to streamline application         |
|          |deployment.                                                        |
|NFS       |Network File System, used for persistent storage in the cluster.   |
|SCC       |Security Context Constraints, OpenShift’s mechanism for controlling|
|          |pod permissions.                                                   |
|PV        |Persistent Volume, a Kubernetes storage resource.                  |
|PVC       |Persistent Volume Claim, a request for storage by a Kubernetes pod.|




Prerequisites




To deploy Oracle Unified Directory (OUD) 14c in an OpenShift cluster, the
following prerequisites must be met:
    • OpenShift Cluster: Version 4.12 or later (based on Kubernetes 1.24+),
      though the original document specifies Kubernetes 1.19.7. Verify OUD
      14c compatibility with your OpenShift version via My Oracle Support
      Doc ID 2723908.1.
    • Administrative Host: A host for deploying the products, which must
      have:
         o oc (OpenShift CLI) installed, matching the cluster version.
         o kubectl installed for compatibility with Kubernetes-based
           operations.
         o Helm installed (version 3.x recommended).
    • NFS Node: Required for persistent storage.
    • Hardware Requirements (per node, suggested for OUD 14c):
         o Disk: 50 GB (for OUD binaries, configs, and OUDSM).
         o Memory: 16 GB.
         o CPU: 4 cores.
    • Helm Chart Components: The Helm chart deploys the following in the
      specified OpenShift namespace:
         o Service Account with appropriate SCC (e.g., restricted or a
           custom SCC for NFS access).
         o Secrets:
               ▪ A Kubernetes secret for credentials to access the
                 container registry (container-registry.oracle.com) where
                 the OUD 14c image is stored.
               ▪ A Kubernetes secret for cronjob images, accessing images
                 on hub.docker.com.
         o Persistent Volume (PV) and Persistent Volume Claim (PVC).
         o Pod(s)/Container(s) for Oracle Unified Directory instances.
         o Services for interfaces exposed through OUD instances.
         o Route (OpenShift-specific, replacing Kubernetes Ingress) for
           external access.


    • OpenShift Cluster Requirements:
         o Must meet minimum version requirements outlined in My Oracle
           Support Doc ID 2723908.1.
         o Sufficient nodes and resources (at least 3 worker nodes
           recommended).
         o CRI-O container engine (default in OpenShift) must be installed
           and running.
         o Nodes must have access to a persistent volume (e.g., NFS mount
           or shared file system). For assured replication in OUD, a
           persistent volume using NFS is required for the config volume
           (see Enabling Assured Replication in Oracle Docs).
         o System clocks on all cluster nodes must be synchronized (use the
           date command to verify and synchronize as needed).
         o OpenShift Security Context Constraints (SCC) must be configured
           to allow NFS access and OUD container requirements (e.g.,
           UID/GID permissions).


Capacity Planning

Recommended Namespace Structure
Based on Oracle documentation and best practices for Kubernetes/OpenShift
deployments, the following namespace structure is recommended for OUD,
OUDSM, and ELK components:
   1. OUD Namespace (oudns):
         o Purpose: Hosts the OUD pods, services, and related resources
           (e.g., Persistent Volumes for OUD binaries and configurations).
         o Rationale: Oracle documentation emphasizes isolating OUD
           instances to simplify management and ensure that directory
           services are separated from other components.
         o Components:
               ▪ OUD pods and containers.
               ▪ Persistent Volume Claims (PVCs) for /u01/oudpv (OUD
                 binaries) and /u01/oudconfigpv (OUD configurations).
               ▪ Services for LDAP interfaces (e.g., ports 1389, 1636).
               ▪ Service Account (oud-sa) with an appropriate SCC (e.g.,
                 restricted or a custom SCC for NFS access).
         o Reference: The provided document mentions deploying OUD in a
           specified namespace with a Service Account and secrets for the
           container registry, supporting a dedicated namespace for OUD.


   2. OUDSM Namespace (oudsmns):
         o Purpose: Hosts the OUDSM pods, NodePort services, and OpenShift
           Routes for the web-based management interface.
         o Rationale: Oracle recommends deploying OUDSM in its own
           lightweight domain to simplify management and reduce
           dependencies. In OpenShift, isolating OUDSM in a separate
           namespace (oudsmns) ensures that the web interface is
           independent of the OUD directory service, improving security and
           scalability.
         o Components:
               ▪ OUDSM pods.
               ▪ Persistent Volume Claim for /u01/oudsmpv (OUDSM
                 components).
               ▪ NodePort service (e.g., port 7001) and OpenShift Route
                 for external access.
               ▪ Service Account (oudsm-sa) with an appropriate SCC.
         o OpenShift Consideration: OUDSM requires a Route for external
           access, which is namespace-specific in OpenShift. A separate
           namespace ensures clean routing configuration.


   3. ELK Namespace (elkns):
         o Purpose: Hosts the ELK Stack components (Elasticsearch,
           Logstash, Kibana) for centralized log monitoring of OUD and
           OUDSM logs.
         o Rationale: Oracle documentation for OUDSM log monitoring
           recommends using a centralized Elasticsearch/Kibana deployment
           with a Logstash pod to process OUD and OUDSM logs. A dedicated
           namespace (elkns) isolates the ELK Stack, aligning with
           Kubernetes best practices for monitoring tools and Oracle’s
           guidance for log file monitoring. This namespace contains the
           Elasticsearch cluster, Logstash pod, and Kibana interface.
         o Components:
               ▪ Elasticsearch pods for storing and indexing logs.
               ▪ Logstash pod configured to read logs from OUD
                 (/u01/oudconfigpv) and OUDSM (/u01/oudsmpv) Persistent
                 Volumes.
               ▪ Kibana pod for visualizing logs.
               ▪ Secrets for Elasticsearch authentication (e.g.,
                 elasticsearch-pw-elastic).
               ▪ ConfigMap for Logstash configuration (e.g., oudsm-
                 logstash-configmap).
               ▪ Service Account (elk-sa) with an appropriate SCC.
         o Reference: Oracle documentation specifies configuring a Logstash
           pod in a namespace (e.g., elkns) to connect to a centralized
           Elasticsearch deployment. The Logstash pod requires access to
           OUD/OUDSM log files via NFS mounts.
Node Requirements
Worker Node Specification:
    • CPU: 16-32 cores per node
    • Memory: 64-128 GB RAM per node
    • Storage: NVMe SSD with high IOPS (10,000+ IOPS per node)
    • Network: 10 Gbps minimum
Recommended Node Count:
    • Minimum: 6-8 worker nodes
    • Optimal: 10-12 worker nodes


OUD Deployment Architecture
1. Multi-Instance Deployment Pattern

    • OUD Directory Server Instances (3-4 replicas)


    • OUD Proxy Server Instances (2-3 replicas)


    • OUD Replication Servers (3 replicas)


    • OUDSM servers (2 replicas)


    • Management/Monitoring Components (3 replicas)

2. Resource Allocation per OUD Instance
    • Directory Server Pods: 8-16 CPU cores, 32-64 GB RAM
    • Proxy Server Pods: 4-8 CPU cores, 16-32 GB RAM
    • Replication Server Pods: 4-8 CPU cores, 16-32 GB RAM
3. Storage Strategy
    • Persistent Volumes: 500GB-1TB per directory instance
    • Storage Class: High-performance SSD with replication
    • Backup Storage: Separate tier for LDIF exports and backups


Deployment Architecture Components
Data Tier (Directory Servers)
    • Deploy 3-4 OUD directory server instances across different nodes
    • Use OpenShift StatefulSets for ordered deployment and stable network
      identities
    • Implement pod anti-affinity rules to ensure instances run on different
      nodes
Proxy Tier
    • Deploy 2-3 OUD proxy instances for load balancing and high
      availability
    • Use OpenShift Deployments with horizontal pod autoscaling
    • Configure with OpenShift Routes/Services for external access
Replication Architecture
    • Set up multi-master replication across directory instances
    • Configure change log databases on separate storage volumes
    • Implement monitoring for replication lag and conflicts
OpenShift-Specific Considerations
Security Context
    • Use dedicated service accounts with appropriate SCCs (Security Context
      Constraints)
    • Implement pod security policies for OUD containers
    • Configure network policies for secure communication
Networking
    • Use OpenShift SDN with network segmentation
    • Configure routes for external LDAP access
    • Implement east-west traffic encryption between pods
Performance Optimization
JVM Tuning
    • Heap size: 16-32 GB per directory instance
    • Use G1 garbage collector for large heaps
    • Configure JVM arguments for container environments
OUD Configuration
    • Enable entry caching with appropriate cache sizes
    • Configure connection pooling and worker threads
    • Optimize database settings for your entry distribution
Monitoring & Observability
    • Use OpenShift logging stack (EFK) for centralized logging
    • Implement health checks and readiness probes

Prepare NFS

Persistent Volumes
 • NFS Server Exports with 777 permissions:
|Local Location |Description                |
|/u01/oudpv     |OUD 14c binaries           |
|/u01/oudsmpv   |OUDSM web interface        |
|               |components                 |
|/u01/oudconfigp|OUD configuration files    |
|v              |                           |


 • NFS Client Mounts:
      o Define mounts on all nodes (control and worker nodes) in
        /etc/fstab:
|Local Location |NFS Mount Configuration                                    |
|/u01/oudpv     |NFS_Server_Name/u01/oudpv /u01/oudpv nfs rw,soft,auto,user…|
|/u01/oudsmpv   |NFS_Server_Name: /u01/oudsmpv /u01/oudsmpv nfs             |
|               |rw,soft,auto,user…                                         |
|/u01/oudconfigp|NFS_Server_Name: /u01/oudconfigpv /u01/oudconfigpv nfs     |
|v              |rw,soft,auto,user…                                         |


 • Firewall Settings for NFS: The storage team must configure firewall rules
   to allow NFS traffic (ports 2049 for NFS, 111 for RPC, etc.) and ensure
   all nodes can access the NFS server.




Prepare OUD/OUDSM Images

To prepare the OUD 14c and OUDSM images for deployment on OpenShift:
   1. Pull OUD Image:
   2. Pull OUDSM Image:
   3. Prepare Cronjob Images:
         o For cronjobs (e.g., backups or maintenance tasks), pull images
           from hub.docker.com if required by your Helm chart.
   4. Tag and Push to OpenShift Registry (optional – probably when we get to
      the stage where we need to apply patches):
         o If using OpenShift’s internal registry, tag and push the images:
         o oc tag container-registry.oracle.com/middleware/oud:14.0.0
           oud:14c
   5. Verify Images:
         o Ensure images are available in the OpenShift image stream:
         o oc get imagestream -n <namespace>











Deploy OUD using Helm





To deploy OUD 14c using Helm on OpenShift:
   1. Obtain the OUD Helm Chart:
         o Download the official Oracle OUD Helm chart from Oracle’s GitHub
           or My Oracle Support.
         o Alternatively, create a custom Helm chart based on Oracle’s
           documentation.
   2. Customize Helm Values:
   3. Create Service Account and SCC
   4. Deploy the Helm Chart:
         o Install the Helm chart in the desired namespace:
   5. Verify Deployment




Deploy OUDSM Pod




To deploy the Oracle Unified Directory Services Manager (OUDSM) pod:
   1. Configure OUDSM in Helm Chart:
   2. Deploy OUDSM:
   3. Verify OUDSM Pod:




Deploy OUDSM NodePort Service




To expose OUDSM externally using a NodePort service in OpenShift:
   1. Create NodePort Service:
   2. Create OpenShift Route:
   3. Access OUDSM:
         o Use the Route URL (e.g., http://oudsm-route-
           <namespace>.apps.<cluster-domain>) to access the OUDSM web
           interface.




Monitor the Pods




To monitor OUD and OUDSM pods in OpenShift:
   1. Check Pod Status:
         o List all pods in the namespace:
         o oc get pods -n <namespace>
   2. View Logs:
         o Check logs for OUD pods:
         o oc logs -l app=oud -n <namespace>
         o Check logs for OUDSM pods:
         o oc logs -l app=oudsm -n <namespace>
   3. Monitor Resources:
         o Use OpenShift’s monitoring tools (e.g., Prometheus, Grafana) to
           track CPU, memory, and network usage.
         o Enable monitoring in the OpenShift console or via:
         o oc get prometheus -n openshift-monitoring
   4. Set Up Alerts:
         o Configure alerts for pod failures or resource thresholds using
           OpenShift’s alerting system.




Sample Use Cases


References





    • Oracle Unified Directory 14c Documentation: Oracle Docs
    • My Oracle Support Doc ID 2723908.1: Kubernetes version requirements
    • OpenShift 4.x Documentation: OpenShift Docs
    • Helm Documentation: Helm Docs
    • Oracle Container Registry: container-registry.oracle.com




2822571.1












```
