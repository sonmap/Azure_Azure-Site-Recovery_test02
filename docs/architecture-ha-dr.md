# HA + ASR DR Architecture

This document describes the corrected HA and DR architecture for this lab.

## Key correction

The **Internal Load Balancer is not a single-VM access component**.

It is included to prepare for **Tomcat VM redundancy / HA**. The load balancer sits in front of two Tomcat VMs and distributes TCP 8080 traffic using a health probe.

## Traffic flow

```text
External Internet
  ↓
Traffic Manager DNS
  ↓
Active site's Internal Load Balancer
  ↓
Tomcat VM HA pair
  ├─ vm-asr-app01 : Linux VM + Tomcat 8080
  └─ vm-asr-app02 : Linux VM + Tomcat 8080
        ↓
      MySQL small DB
```

## Primary site: Korea Central

```text
rg-asr-src-krc
└─ vnet-asr-src-krc
   └─ snet-app
      ├─ Internal Load Balancer: ilb-asr-app-krc
      │  ├─ Frontend: fe-app
      │  ├─ Backend pool: be-tomcat-8080
      │  ├─ Probe: probe-tomcat-8080
      │  └─ Rule: TCP 8080 → TCP 8080
      ├─ vm-asr-app01 : Linux VM + Tomcat 8080
      ├─ vm-asr-app02 : Linux VM + Tomcat 8080
      ├─ MySQL small DB
      └─ Cache Storage Account for ASR
```

## DR site: Japan East

The DR site follows the same logical application pattern.

```text
rg-asr-dr-jpe
└─ vnet-asr-dr-jpe
   └─ snet-app
      ├─ Internal Load Balancer for DR traffic after failover
      ├─ vm-asr-app01-dr : recovered Linux VM + Tomcat 8080
      ├─ vm-asr-app02-dr : recovered Linux VM + Tomcat 8080
      ├─ MySQL small DB
      └─ Target managed disks / NICs after ASR failover
```

## Traffic Manager DNS role

Traffic Manager DNS is used as the **site selection layer**.

It should direct clients to the active site path. In this lab architecture, that means the active site's internal application entry path:

```text
Traffic Manager DNS → active site Internal Load Balancer → Tomcat VM HA pair
```

For an enterprise private network, this assumes the client has a valid network path to the private application entry point through corporate routing, DNS, VPN, ExpressRoute, proxy, or an approved ingress path.

## Internal Load Balancer role

The Internal Load Balancer exists for:

- Tomcat VM redundancy
- Active site HA
- TCP 8080 load balancing
- Health probe based routing
- Future scale-out from 2 VMs to more VMs

It should not be documented as a simple one-to-one path to a single VM.

## ASR replication scope

ASR protects the source VMs and their managed disks.

```text
vm-asr-app01 ── ASR replication ──> vm-asr-app01-dr
vm-asr-app02 ── ASR replication ──> vm-asr-app02-dr
```

The script below generates the ASR protected item CSV from the shared inventory and VM Terraform outputs:

```bash
python3 scripts/generate_protected_vms.py
```

## Important implementation note

This lab now creates the **primary site Internal Load Balancer** in `10-vm` and associates the source Tomcat VMs with its backend pool.

DR-side load balancer backend association may require a post-failover step because ASR-created NICs are only available after failover. That step can be handled by Automation Runbook, Azure CLI, or manual validation during a DR drill.
