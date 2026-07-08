param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Status", "TestFailover", "CleanupTestFailover", "PlannedFailover", "UnplannedFailover")]
    [string]$Mode,

    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$VaultResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$VaultName,

    [Parameter(Mandatory = $true)]
    [string]$SourceFabricName,

    [Parameter(Mandatory = $true)]
    [string]$SourceProtectionContainerName,

    [Parameter(Mandatory = $true)]
    [string]$ProtectedItemFriendlyName,

    [Parameter(Mandatory = $false)]
    [string]$TargetNetworkId,

    [Parameter(Mandatory = $false)]
    [ValidateSet("PrimaryToRecovery", "RecoveryToPrimary")]
    [string]$Direction = "PrimaryToRecovery",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Latest", "LatestAvailable", "LatestAvailableApplicationConsistent", "LatestAvailableCrashConsistent")]
    [string]$RecoveryTag = "LatestAvailable",

    [Parameter(Mandatory = $false)]
    [bool]$WaitForJob = $true
)

$ErrorActionPreference = "Stop"

function Wait-AsrJob {
    param(
        [Parameter(Mandatory = $true)]
        $Job
    )

    Write-Output "ASR job started. Job name: $($Job.Name)"

    do {
        Start-Sleep -Seconds 30
        $CurrentJob = Get-AzRecoveryServicesAsrJob -Name $Job.Name
        Write-Output "ASR job state: $($CurrentJob.State)"
    } while ($CurrentJob.State -in @("NotStarted", "InProgress"))

    Write-Output "ASR final job state: $($CurrentJob.State)"

    if ($CurrentJob.State -ne "Succeeded") {
        throw "ASR job did not succeed. Final state: $($CurrentJob.State)"
    }

    return $CurrentJob
}

Write-Output "Disable inherited Az context"
Disable-AzContextAutosave -Scope Process | Out-Null

Write-Output "Login with Automation Account managed identity"
$AzureContext = Connect-AzAccount -Identity
Set-AzContext -SubscriptionId $SubscriptionId -DefaultProfile $AzureContext | Out-Null

Write-Output "Set Recovery Services Vault context"
$Vault = Get-AzRecoveryServicesVault -ResourceGroupName $VaultResourceGroupName -Name $VaultName
Set-AzRecoveryServicesAsrVaultContext -Vault $Vault | Out-Null

Write-Output "Find ASR fabric, protection container, and protected item"
$Fabric = Get-AzRecoveryServicesAsrFabric -Name $SourceFabricName

$ProtectionContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $Fabric |
    Where-Object { $_.Name -eq $SourceProtectionContainerName }

if (-not $ProtectionContainer) {
    throw "ASR protection container not found: $SourceProtectionContainerName"
}

$ReplicationProtectedItem = Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $ProtectionContainer |
    Where-Object { $_.FriendlyName -eq $ProtectedItemFriendlyName }

if (-not $ReplicationProtectedItem) {
    throw "ASR replication protected item not found: $ProtectedItemFriendlyName"
}

Write-Output "Protected item: $($ReplicationProtectedItem.FriendlyName)"
Write-Output "Protection state: $($ReplicationProtectedItem.ProtectionState)"
Write-Output "Replication health: $($ReplicationProtectedItem.ReplicationHealth)"

switch ($Mode) {
    "Status" {
        Write-Output "Mode: Status"
        $ReplicationProtectedItem |
            Select-Object FriendlyName, ProtectionState, ReplicationHealth, AllowedOperations
    }

    "TestFailover" {
        if ([string]::IsNullOrWhiteSpace($TargetNetworkId)) {
            throw "TargetNetworkId is required for TestFailover mode."
        }

        Write-Output "Mode: TestFailover"
        Write-Output "Direction: $Direction"
        Write-Output "TargetNetworkId: $TargetNetworkId"

        $Job = Start-AzRecoveryServicesAsrTestFailoverJob `
            -ReplicationProtectedItem $ReplicationProtectedItem `
            -Direction $Direction `
            -AzureVMNetworkId $TargetNetworkId `
            -Confirm:$false

        if ($WaitForJob) {
            Wait-AsrJob -Job $Job
        }
        else {
            $Job
        }
    }

    "CleanupTestFailover" {
        Write-Output "Mode: CleanupTestFailover"

        $Job = Start-AzRecoveryServicesAsrTestFailoverCleanupJob `
            -ReplicationProtectedItem $ReplicationProtectedItem `
            -Comment "Cleanup from Azure Automation runbook" `
            -Confirm:$false

        if ($WaitForJob) {
            Wait-AsrJob -Job $Job
        }
        else {
            $Job
        }
    }

    "PlannedFailover" {
        Write-Output "Mode: PlannedFailover"
        Write-Output "Direction: $Direction"

        $Job = Start-AzRecoveryServicesAsrPlannedFailoverJob `
            -ReplicationProtectedItem $ReplicationProtectedItem `
            -Direction $Direction `
            -Confirm:$false

        if ($WaitForJob) {
            Wait-AsrJob -Job $Job
        }
        else {
            $Job
        }
    }

    "UnplannedFailover" {
        Write-Output "Mode: UnplannedFailover"
        Write-Output "Direction: $Direction"
        Write-Output "RecoveryTag: $RecoveryTag"

        $Job = Start-AzRecoveryServicesAsrUnplannedFailoverJob `
            -ReplicationProtectedItem $ReplicationProtectedItem `
            -Direction $Direction `
            -RecoveryTag $RecoveryTag `
            -Confirm:$false

        if ($WaitForJob) {
            Wait-AsrJob -Job $Job
        }
        else {
            $Job
        }
    }
}
