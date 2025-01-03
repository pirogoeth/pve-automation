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
        hostname = "${ingress_rule.value["subdomain"]}.${local.base_domain}"
        path     = lookup(ingress_rule.value, "path", "")
        service  = ingress_rule.value["target"]
        origin_request {
          http_host_header   = "${ingress_rule.value["subdomain"]}.${local.base_domain}"
          origin_server_name = "${ingress_rule.value["subdomain"]}.${local.base_domain}"
        }
      }
    }

    # Last rule must be a match-all action
    ingress_rule {
      service = "http_status:404"
    }
  }
}

resource "cloudflare_record" "tunnelled_subdomain" {
  for_each = {
    for item in var.tunnel_forwards :
    "${item.subdomain}.${local.base_domain}" => local.tunnel_domain
  }

  zone_id = data.cloudflare_zone.main.id
  name    = each.key
  content = each.value
  type    = "CNAME"
  proxied = true
}
