locals {
  asr_settings_raw = csvdecode(file("${path.module}/data/asr_settings.csv"))
  protected_vms_raw = csvdecode(file("${path.module}/data/protected_vms.csv"))

  asr_settings = {
    for s in local.asr_settings_raw : s.key => merge(s, {
      recovery_point_retention_in_minutes                    = tonumber(s.recovery_point_retention_in_minutes)
      application_consistent_snapshot_frequency_in_minutes   = tonumber(s.application_consistent_snapshot_frequency_in_minutes)
    })
  }

  asr = local.asr_settings["default"]

  protected_vms = {
    for vm in local.protected_vms_raw : vm.replication_name => vm
    if !startswith(vm.source_vm_id, "<") && !startswith(vm.os_disk_id, "<")
  }

  target_resource_group_names = toset([
    for vm in local.protected_vms : vm.target_resource_group_name
  ])
}
