# 30-runbook

This Terraform layer deploys an Azure Automation Account and an ASR failover runbook.

## Purpose

The runbook is intended for controlled ASR operations:

- `Status`
- `TestFailover`
- `CleanupTestFailover`
- `PlannedFailover`
- `UnplannedFailover`

For production, do not run planned or unplanned failover without an approval process.

## Configure

```bash
cp 30-runbook/terraform.tfvars.example 30-runbook/sonmap.auto.tfvars
```

Edit the tenant and subscription values.

Review:

```bash
30-runbook/data/runbook_settings.csv
```

## Deploy

```bash
terraform -chdir=30-runbook init
terraform -chdir=30-runbook fmt -recursive
terraform -chdir=30-runbook validate
terraform -chdir=30-runbook plan -out=tfplan
terraform -chdir=30-runbook apply tfplan
```

## Required Automation modules

Confirm the Automation Account has these PowerShell modules available:

- `Az.Accounts`
- `Az.RecoveryServices`
- `Az.Resources`
- `Az.Network`

## Example runbook parameters

### Status

```powershell
Mode                          = Status
SubscriptionId                = <SUBSCRIPTION_ID>
VaultResourceGroupName        = rg-asr-vault-jpe
VaultName                     = rsv-asr-dr-jpe
SourceFabricName              = asr-fabric-krc
SourceProtectionContainerName = asr-container-krc
ProtectedItemFriendlyName     = vm-asr-app01
```

### Test failover

```powershell
Mode                          = TestFailover
SubscriptionId                = <SUBSCRIPTION_ID>
VaultResourceGroupName        = rg-asr-vault-jpe
VaultName                     = rsv-asr-dr-jpe
SourceFabricName              = asr-fabric-krc
SourceProtectionContainerName = asr-container-krc
ProtectedItemFriendlyName     = vm-asr-app01
TargetNetworkId               = /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-asr-dr-jpe/providers/Microsoft.Network/virtualNetworks/vnet-asr-dr-jpe
Direction                     = PrimaryToRecovery
WaitForJob                    = true
```

## Permission note

This lab assigns `Contributor` to the vault resource group and DR resource group for simplicity. For production, reduce this to the least privilege roles required for ASR operation.
