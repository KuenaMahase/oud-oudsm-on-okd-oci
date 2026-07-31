# Artifacts To Be Created On Oud Kubernetes Cluster

> Converted from a historical working `.doc` artifact and sanitized for publication.

```text





NFS Server Exports

|NFS Share Name                 |Size                     |Description           |
|oudpv_qa_nfs                   |200 GB                   |OUD Binaries          |
|oudsmpv_qa_nsf                 |200 GB                   |UI for OUD Components.|
|oudconfigpv_qa_nsf             |200 GB                   |OUD Configs.          |


Master & Worker Nodes Mount Points Definitions

|NFS Share                                        |Nodes Mount Points           |
|NFS_Server_Name: /export/oudpv_qa_nfs            |/u01/oudpv                   |
|NFS_Server_Name: /export/oudsmpv_qa_nsf          |/u01/oudsmpv                 |
|NFS_Server_Name: /export/oudconfigpv _qa_nsf     |/u01/oudconfigpv             |



OUD Cluster Name Spaces


|Name                            |Description                                    |
|oudns                           |Hosts OUD pods, services, and Persistent       |
|                                |Volumes for binaries and configurations.       |
|oudsmns                         |Hosts OUDSM pods, NodePort services, and       |
|                                |OpenShift Routes for the web-based management  |
|                                |interface.                                     |
|elkns                           |Hosts ELK Stack (Elasticsearch, Logstash,      |
|                                |Kibana) for centralized log monitoring.        |





Node Requirements
    • Worker Node Specification:
         o CPU: 16-32 cores.
         o Memory: 64-128 GB RAM.
         o Storage: NVMe SSD, 10,000+ IOPS.
         o Network: 10 Gbps.
    • Node Count:
         o Minimum: 6-8 nodes.
         o Optimal: 10-12 nodes for redundancy and scalability.

















```
