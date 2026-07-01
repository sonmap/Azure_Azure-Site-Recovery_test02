locals {
  resource_groups_raw = csvdecode(file("${path.module}/data/resource_groups.csv"))
  vnets_raw           = csvdecode(file("${path.module}/data/vnets.csv"))
  subnets_raw         = csvdecode(file("${path.module}/data/subnets.csv"))
  nsgs_raw            = csvdecode(file("${path.module}/data/nsgs.csv"))
  nsg_rules_raw       = csvdecode(file("${path.module}/data/nsg_rules.csv"))

  resource_groups = {
    for rg in local.resource_groups_raw : rg.resource_group_name => rg
  }

  vnets = {
    for v in local.vnets_raw : v.vnet_name => merge(v, {
      address_space = split("|", v.address_space)
      dns_servers   = length(trimspace(v.dns_servers)) > 0 ? split("|", v.dns_servers) : null
    })
  }

  subnets = {
    for s in local.subnets_raw : "${s.vnet_name}/${s.subnet_name}" => merge(s, {
      address_prefixes = split("|", s.address_prefixes)
    })
  }

  nsgs = {
    for n in local.nsgs_raw : n.nsg_name => n
  }

  nsg_rules = {
    for idx, r in local.nsg_rules_raw : "${r.nsg_name}/${idx}-${r.rule_name}" => r
  }
}
