data "cloudflare_zone" "main" {
  name = var.dns_zone_name
}

locals {
  dns_zone_mapping = {
    for forward in var.tunnel_forwards :
    ("${forward.subdomain}.${coalesce(forward.domain, var.dns_zone_name)}") => coalesce(forward.domain, var.dns_zone_name)...
  }
  dns_zones = {
    for subdomain, dns_zone_names in local.dns_zone_mapping :
    (subdomain) => distinct(dns_zone_names)[0]
  }
}

data "cloudflare_zone" "zones" {
  for_each = local.dns_zones

  name = each.value
}

data "cloudflare_zero_trust_tunnel_cloudflared" "tunnel" {
  account_id = var.cloudflare_account_id
  name       = var.cloudflare_tunnel_name
}
