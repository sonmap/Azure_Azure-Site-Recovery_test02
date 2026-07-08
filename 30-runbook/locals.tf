locals {
  runbook_settings_raw = csvdecode(file("${path.module}/data/runbook_settings.csv"))

  runbook_settings = {
    for s in local.runbook_settings_raw : trimspace(s.key) => merge(s, {
      key = trimspace(s.key)
    })
  }

  runbook = local.runbook_settings["default"]
}
