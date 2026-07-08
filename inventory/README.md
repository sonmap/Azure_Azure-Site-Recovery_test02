# Azure-aligned Inventory

This directory defines a **custom Azure-aligned inventory standard** for this repository.

It is not an Azure-native required file format. Azure does not require a CSV inventory file for deployment. This repository uses CSV inventory files as Terraform input data and operational documentation.

## Files

| File | Purpose |
| --- | --- |
| `azure_inventory_standard.csv` | Common inventory schema aligned to Azure Resource Manager, Azure Resource Graph, tags, and IaC metadata |
| `tag_standard.csv` | Recommended Azure tag keys and allowed values for this lab |
| `vm_inventory.csv` | Workload VM inventory used by `10-vm` and the ASR protected VM generation script |

## Source of truth

Use this split of responsibility:

| Phase | Source |
| --- | --- |
| Before deployment | `inventory/*.csv` |
| During deployment | Terraform configuration and state |
| After deployment | Azure Resource Graph / Azure Portal / Azure CLI |
| Cost, owner, and operation classification | Azure tags |

## Important note

`resource_id`, `os_disk_id`, and `source_nic_id` are only available after the VM is created. For ASR, run:

```bash
terraform -chdir=10-vm output -json
python3 scripts/generate_protected_vms.py
```

The script generates `20-asr/data/protected_vms.csv` from `inventory/vm_inventory.csv` and Terraform outputs.
