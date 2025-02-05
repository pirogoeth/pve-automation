locals {
  traefik_addresses = [
    for item in data.terraform_remote_state.infra.outputs.nomad_client_inventory
    : item.ip
  ]
  minio_addresses = [
    for item in data.terraform_remote_state.infra.outputs.minio_server_inventory
    : item.ip
  ]
  service_names = [
    "changedet",
    "grafana",
    "handbrake",
    "langfuse",
    "llms",
    "loki",
    "n8n",
    "news",
    "ollama",
    "plex",
    "prometheus",
  ]
}

resource "dns_a_record_set" "traefik" {
  zone      = "${var.service_base_domain}."
  name      = "traefik"
  addresses = local.traefik_addresses
  ttl       = 300
}

import {
  to = dns_a_record_set.traefik
  id = "traefik.${var.service_base_domain}."
}

resource "dns_a_record_set" "minio" {
  zone      = "${var.service_base_domain}."
  name      = "s3"
  addresses = local.minio_addresses
  ttl       = 300
}

import {
  to = dns_a_record_set.minio
  id = "s3.${var.service_base_domain}."
}

resource "dns_cname_record" "minio_glob" {
  zone  = "${var.service_base_domain}."
  name  = "*.s3"
  cname = dns_a_record_set.minio.id
  ttl   = 300
}

import {
  to = dns_cname_record.minio_glob
  id = "*.s3.${var.service_base_domain}."
}

resource "dns_cname_record" "services" {
  for_each = toset(local.service_names)

  zone  = "${var.service_base_domain}."
  name  = each.key
  cname = dns_a_record_set.traefik.id
  ttl   = 3600
}

import {
  for_each = toset(local.service_names)

  to = dns_cname_record.services[each.key]
  id = "${each.key}.${var.service_base_domain}."
}

