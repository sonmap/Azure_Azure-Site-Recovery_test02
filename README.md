# Azure Site Recovery DR Lab

Terraform lab for **Azure VM disaster recovery** using **Azure Site Recovery (ASR)**.

This repository was built from the staged style of `sonmap/azure-EntraID-AKS-small_comapy`: separate Terraform layers, CSV-driven inputs, and local `*.auto.tfvars` for real tenant/subscription values.

> Important: ASR protects Azure VMs. AKS cluster DR is normally handled by redeploying the cluster and restoring application/data state, not by replicating the AKS control plane with ASR. This repo therefore creates a VM-based ASR DR pattern that can sit beside the original Entra ID + AKS lab.

## Target architecture

```text
External Internet
  ↓
Traffic Manager DNS
  ↓
Active site's Internal Load Balancer
  ↓
Tomcat VM HA pair on TCP 8080
  ↓
MySQL small DB
```

```text
Korea Central / Seoul side                         Japan East / DR side
──────────────────────────                         ─────────────────────────
rg-asr-src-krc                                      rg-asr-dr-jpe
vnet-asr-src-krc                                    vnet-asr-dr-jpe
snet-app                                            snet-app

Internal Load Balancer                              Internal Load Balancer after failover
├─ vm-asr-app01 : Linux VM + Tomcat 8080             ├─ vm-asr-app01-dr : Linux VM + Tomcat 8080
└─ vm-asr-app02 : Linux VM + Tomcat 8080             └─ vm-asr-app02-dr : Linux VM + Tomcat 8080

MySQL small DB                                      MySQL small DB
Cache Storage Account                               Target managed disks / NICs

vm-asr-app01  ── ASR replication ────────────────>  vm-asr-app01-dr
vm-asr-app02  ── ASR replication ────────────────>  vm-asr-app02-dr

Recovery Services Vault: rg-asr-vault-jpe / rsv-asr-dr-jpe
Automation Account:       rg-asr-vault-jpe / aa-asr-dr-jpe
```

The **Internal Load Balancer is for VM redundancy / HA**. It is not a one-to-one access path to a single VM. Traffic Manager DNS is the site-selection layer and should direct clients to the active site's application entry path.

The Tomcat application includes a DB status page that attempts a real JDBC connection to MySQL and displays DB host, resolved DB IP, configured DB region, connected DB hostname, database name, DB version, and DB time.

For more detail, see:

- [`docs/architecture-ha-dr.md`](docs/architecture-ha-dr.md)
- [`docs/db-status-page.md`](docs/db-status-page.md)

## Folder layout

```text
.
├── inventory/       # Azure-aligned custom inventory and tag schema
├── 00-network/      # Primary + DR resource groups, VNets, subnets, NSGs
├── 10-vm/           # Source Tomcat VM HA pair + Internal Load Balancer
├── 20-asr/          # Recovery Services Vault + ASR replication objects
├── 30-runbook/      # Azure Automation Account + ASR failover runbook
├── docs/            # Manual failover, validation, and architecture notes
└── scripts/         # Convenience deployment and inventory generation scripts
```

## Inventory model

This repository uses a **custom Azure-aligned inventory standard**.

It is not an Azure-native required file format. The inventory files are Terraform input and operational documentation. After deployment, the actual Azure inventory should be confirmed from Azure Resource Graph, Azure Portal, Azure CLI, or Terraform state.

| File | Purpose |
| --- | --- |
| `inventory/azure_inventory_standard.csv` | Common inventory schema aligned to Azure Resource Manager, tags, and IaC metadata |
| `inventory/tag_standard.csv` | Recommended Azure tag standard for this lab |
| `inventory/vm_inventory.csv` | VM, ASR, DR, and runbook workload inventory |

## Deployment order

### 1. Configure common variables

Each Terraform stage has `terraform.tfvars.example`. Copy it locally and never commit the real file.

```bash
cp 00-network/terraform.tfvars.example 00-network/sonmap.auto.tfvars
cp 10-vm/terraform.tfvars.example 10-vm/sonmap.auto.tfvars
cp 20-asr/terraform.tfvars.example 20-asr/sonmap.auto.tfvars
cp 30-runbook/terraform.tfvars.example 30-runbook/sonmap.auto.tfvars
```

Edit each `sonmap.auto.tfvars` with your real values:

```hcl
tenant_id       = "<TENANT_ID>"
subscription_id = "<SUBSCRIPTION_ID>"
```

For the Tomcat DB status page, configure MySQL connection values in `10-vm/sonmap.auto.tfvars`:

```hcl
mysql_host     = "<MYSQL_FQDN_OR_PRIVATE_IP>"
mysql_port     = 3306
mysql_database = "appdb"
mysql_username = "appuser"
mysql_password = "<PASSWORD>"
mysql_region   = "koreacentral"
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

### 3. Deploy source Tomcat VM HA pair

`10-vm` reads VM definitions from `inventory/vm_inventory.csv`.

This stage deploys:

- `vm-asr-app01`
- `vm-asr-app02`
- Tomcat on TCP 8080 using cloud-init
- DB status page: `/db-status.jsp`
- Primary site Internal Load Balancer `ilb-asr-app-krc`
- TCP 8080 health probe and load-balancing rule

```bash
cd ../10-vm
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

After deployment, get the Internal Load Balancer IP and test the DB status page:

```bash
terraform -chdir=10-vm output internal_load_balancer_private_ip
curl http://<internal-load-balancer-ip>:8080/db-status.jsp
```

### 4. Generate ASR protected VM data

ASR needs Azure resource IDs that only exist after the source VMs are created. Generate `20-asr/data/protected_vms.csv` from inventory and Terraform outputs:

```bash
cd ..
python3 scripts/generate_protected_vms.py
```

The script reads:

- `inventory/vm_inventory.csv`
- `terraform -chdir=10-vm output -json vm_ids`
- `terraform -chdir=10-vm output -json vm_os_disk_ids`
- `terraform -chdir=10-vm output -json vm_nic_ids`

### 5. Enable ASR replication

```bash
cd 20-asr
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

ASR replication can take time after Terraform creates the protected items. Check the Recovery Services Vault > Replicated items page before running a test failover.

### 6. Deploy Automation Runbook

```bash
cd ../30-runbook
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

After deployment, confirm the Automation Account has the required PowerShell modules:

- `Az.Accounts`
- `Az.RecoveryServices`
- `Az.Resources`
- `Az.Network`

## DB status page

The Tomcat DB status page is deployed at:

```text
/db-status.jsp
```

It displays:

- JDBC connection result
- configured DB host
- resolved DB IP
- configured DB region
- connected DB hostname from MySQL
- current database
- DB version
- DB time
- web server time
- connection error, if any

See [`docs/db-status-page.md`](docs/db-status-page.md) for details.

## Key files to edit

| File | Purpose |
| --- | --- |
| `inventory/vm_inventory.csv` | Primary workload inventory for Tomcat VMs, ASR, and runbook settings |
| `inventory/tag_standard.csv` | Azure tag standard |
| `00-network/data/*.csv` | Seoul/Japan network, subnet, NSG values |
| `10-vm/cloud-init-tomcat.yaml` | Tomcat installation, JDBC driver setup, and DB status page bootstrap |
| `10-vm/lb.tf` | Primary site Internal Load Balancer for Tomcat VM HA |
| `10-vm/terraform.tfvars.example` | Example MySQL connection variables for DB status page |
| `20-asr/data/asr_settings.csv` | Vault, ASR fabric/container, policy, cache storage settings |
| `20-asr/data/protected_vms.csv` | Generated ASR source VM ID, OS disk ID, and NIC ID data |
| `30-runbook/data/runbook_settings.csv` | Automation Account and ASR vault settings |
| `30-runbook/runbooks/Invoke-AsrFailover.ps1` | ASR status, test failover, cleanup, planned failover, and unplanned failover script |

## Notes before production use

- Replace the example SSH public key with your own key.
- Change the cache storage account name. Azure Storage account names must be globally unique.
- For private-only enterprise networks, replace public SSH access with Bastion, VPN, ExpressRoute, or jumpbox access.
- Confirm source VM outbound access to Azure Site Recovery, Storage, Microsoft Entra ID, Event Hub, GuestAndHybridManagement, and package repositories needed for Tomcat/JDBC installation.
- Traffic Manager DNS is a DNS/site-selection layer. Confirm the actual enterprise ingress path to the private Internal Load Balancer, such as corporate routing, DNS, proxy, VPN, or ExpressRoute.
- Run **Test failover** before relying on this DR plan.
- DR-side Internal Load Balancer backend association may require a post-failover runbook or manual validation because ASR-created NICs exist after failover.
- Do not run `PlannedFailover` or `UnplannedFailover` from Automation without a formal approval process.
- The DB status page stores connection values from Terraform-rendered cloud-init. This is for lab validation only.
- Terraform state can contain sensitive values such as `mysql_password`. Use Key Vault, Managed Identity, private endpoints, and a secure state backend before production use.
- The runbook uses broad lab permissions for simplicity. Reduce permissions before production use.

## Useful commands

```bash
# Show source VM IDs after 10-vm deployment
terraform -chdir=10-vm output vm_ids
terraform -chdir=10-vm output vm_os_disk_ids
terraform -chdir=10-vm output vm_nic_ids
terraform -chdir=10-vm output internal_load_balancer_private_ip

# Test DB status page through the Internal Load Balancer
curl http://$(terraform -chdir=10-vm output -raw internal_load_balancer_private_ip):8080/db-status.jsp

# Generate ASR protected VM CSV from inventory and Terraform outputs
python3 scripts/generate_protected_vms.py

# Show ASR objects after 20-asr deployment
terraform -chdir=20-asr output

# Show Automation runbook objects after 30-runbook deployment
terraform -chdir=30-runbook output
```
