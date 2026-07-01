# Azure Site Recovery DR Lab

Terraform lab for **Azure VM disaster recovery** using **Azure Site Recovery (ASR)**.

This repository was built from the staged style of `sonmap/azure-EntraID-AKS-small_comapy`: separate Terraform layers, CSV-driven inputs, and local `*.auto.tfvars` for real tenant/subscription values.

> Important: ASR protects Azure VMs. AKS cluster DR is normally handled by redeploying the cluster and restoring application/data state, not by replicating the AKS control plane with ASR. This repo therefore creates a VM-based ASR DR pattern that can sit beside the original Entra ID + AKS lab.

## Target architecture

```text
Korea Central / Seoul side                 Japan East / DR side
──────────────────────────                 ─────────────────────────
rg-asr-src-krc                              rg-asr-dr-jpe
vnet-asr-src-krc                            vnet-asr-dr-jpe
snet-app                                    snet-app
vm-asr-app01  ── ASR replication ────────>  recovered VM on failover
cache storage account                       target managed disks / NIC

Recovery Services Vault: rg-asr-vault-jpe / rsv-asr-dr-jpe
```

## Folder layout

```text
.
├── 00-network/      # Primary + DR resource groups, VNets, subnets, NSGs
├── 10-vm/           # Source VM set in Korea Central
├── 20-asr/          # Recovery Services Vault + ASR replication objects
├── docs/            # Failover and validation runbook
└── scripts/         # Convenience deployment script
```

## Deployment order

### 1. Configure common variables

Each stage has `terraform.tfvars.example`. Copy it locally and never commit the real file.

```bash
cp 00-network/terraform.tfvars.example 00-network/sonmap.auto.tfvars
cp 10-vm/terraform.tfvars.example 10-vm/sonmap.auto.tfvars
cp 20-asr/terraform.tfvars.example 20-asr/sonmap.auto.tfvars
```

Edit each `sonmap.auto.tfvars` with your real values:

```hcl
tenant_id       = "<TENANT_ID>"
subscription_id = "<SUBSCRIPTION_ID>"
```

### 2. Deploy network

```bash
cd 00-network
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

### 3. Deploy source VM

```bash
cd ../10-vm
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Copy the `vm_ids`, `vm_os_disk_ids`, and `vm_nic_ids` outputs into `20-asr/data/protected_vms.csv`.

### 4. Enable ASR replication

```bash
cd ../20-asr
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

ASR replication can take time after Terraform creates the protected item. Check the Recovery Services Vault > Replicated items page before running a test failover.

## Key files to edit

| File | Purpose |
| --- | --- |
| `00-network/data/*.csv` | Seoul/Japan network, subnet, NSG values |
| `10-vm/data/virtual_machines.csv` | Source VM list |
| `20-asr/data/asr_settings.csv` | Vault, ASR fabric/container, policy, cache storage settings |
| `20-asr/data/protected_vms.csv` | Source VM ID, OS disk ID, and NIC ID to protect |

## Notes before production use

- Replace the example SSH public key with your own key.
- Change the cache storage account name. Azure Storage account names must be globally unique.
- For private-only enterprise networks, replace public SSH access with Bastion, VPN, ExpressRoute, or jumpbox access.
- Confirm source VM outbound access to Azure Site Recovery, Storage, Microsoft Entra ID, Event Hub, and GuestAndHybridManagement service tags on TCP 443.
- Run **Test failover** before relying on this DR plan.

## Useful commands

```bash
# Show source VM IDs after 10-vm deployment
terraform -chdir=10-vm output vm_ids
terraform -chdir=10-vm output vm_os_disk_ids
terraform -chdir=10-vm output vm_nic_ids

# Show ASR objects after 20-asr deployment
terraform -chdir=20-asr output
```
