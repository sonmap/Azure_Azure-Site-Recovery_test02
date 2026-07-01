# ASR Failover Runbook

## 1. Pre-check

Before a failover or test failover:

1. Confirm `20-asr` Terraform apply completed successfully.
2. In the Recovery Services Vault, check that the protected VM appears under **Replicated items**.
3. Confirm replication health is normal.
4. Confirm the target VNet/subnet exists in Japan East.
5. Confirm the target region has enough quota for the VM size.
6. Confirm application owners approve the test window.

## 2. Test failover

Use test failover first. Do not perform an unplanned failover for a normal DR drill.

Recommended sequence:

1. Go to the Recovery Services Vault.
2. Open **Replicated items**.
3. Select the protected VM.
4. Select **Test failover**.
5. Choose the latest recovery point or app-consistent recovery point.
6. Select the DR VNet/subnet.
7. Start test failover.
8. Validate VM boot, network, SSH, service status, and application logs.
9. Clean up the test failover.

## 3. Planned failover

Use planned failover when the source region is still available and you want minimum data loss.

1. Stop application writes if possible.
2. Trigger planned failover from the vault.
3. Validate target VM.
4. Update DNS/LB/routing if the DR VM becomes active.
5. Commit failover only after validation.

## 4. Unplanned failover

Use only during real outage or source-side unrecoverable failure.

1. Confirm incident commander approval.
2. Trigger failover from the latest usable recovery point.
3. Validate target VM and application.
4. Update DNS/LB/routing.
5. Record RTO/RPO timestamps.

## 5. Failback planning

Failback is not just a Terraform operation. Plan the reverse replication direction, data consistency, DNS rollback, application freeze window, and source-region rebuild status before switching back.

## 6. Validation checklist

| Check | Command / place |
| --- | --- |
| VM booted | Azure Portal / VM overview |
| SSH reachable | `ssh azureuser@<DR_IP>` |
| Disk mounted | `lsblk`, `df -h` |
| Service running | `systemctl status <service>` |
| Network route | `ip route`, NSG effective rules |
| Logs normal | `/var/log/syslog`, application logs |
