locals {
  base_domain   = data.cloudflare_zone.main.name
  tunnel_domain = "${data.cloudflare_zero_trust_tunnel_cloudflared.tunnel.id}.cfargotunnel.com"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "tunnel_config" {
  account_id = data.cloudflare_zero_trust_tunnel_cloudflared.tunnel.account_id
  tunnel_id  = data.cloudflare_zero_trust_tunnel_cloudflared.tunnel.id

  config {
    dynamic "ingress_rule" {
      for_each = var.tunnel_forwards
      content {
        hostname = "${ingress_rule.value["subdomain"]}.${data.cloudflare_zone.zones["${ingress_rule.value["subdomain"]}.${coalesce(ingress_rule.value["domain"], var.dns_zone_name)}"].name}"
        path     = lookup(ingress_rule.value, "path", "")
        service  = ingress_rule.value["target"]

        origin_request {
          # Set the Host header for requests to the local service
          http_host_header = "${ingress_rule.value["subdomain"]}.${data.cloudflare_zone.zones["${ingress_rule.value["subdomain"]}.${coalesce(ingress_rule.value["domain"], var.dns_zone_name)}"].name}"

          # Set the name that should be expected when the TLS negotiation with the backend takes place
          origin_server_name = "${ingress_rule.value["subdomain"]}.${data.cloudflare_zone.zones["${ingress_rule.value["subdomain"]}.${coalesce(ingress_rule.value["domain"], var.dns_zone_name)}"].name}"

          # Disable Cloudflare's happy eyeballs protocol (read more elsewhere)
          no_happy_eyeballs = lookup(ingress_rule.value["origin_settings"], "no_happy_eyeballs", false)

          dynamic "access" {
            for_each = ingress_rule.value["access"] != null ? { access = ingress_rule.value["access"] } : {}

            content {
              required  = access.value["required"]
              team_name = var.cloudflare_zt_team_name
              aud_tag   = access.value["audience_tags"]
            }
          }
        }
      }
    }

    # Last rule must be a match-all action
    ingress_rule {
      service = "http_status:404"
    }
  }
}

locals {
  tunneled_fqdns = [
    for item in var.tunnel_forwards :
    "${item.subdomain}.${data.cloudflare_zone.zones["${item.subdomain}.${coalesce(item.domain, var.dns_zone_name)}"].name}"
  ]
  tunnel_mapping = {
    for item in distinct(local.tunneled_fqdns) :
    item => local.tunnel_domain
  }
}

resource "cloudflare_record" "tunnelled_subdomain" {
  for_each = local.tunnel_mapping

  zone_id = data.cloudflare_zone.main.id
  name    = each.key
  content = each.value
  type    = "CNAME"
  proxied = true
}
