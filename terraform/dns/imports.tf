import {
  to = dns_a_record_set.traefik
  id = "traefik.${var.service_base_domain}."
}

import {
  to = dns_a_record_set.minio
  id = "s3.${var.service_base_domain}."
}

import {
  to = dns_cname_record.minio_glob
  id = "*.s3.${var.service_base_domain}."
}

import {
  for_each = toset(local.service_names)

  to = dns_cname_record.services[each.key]
  id = "${each.key}.${var.service_base_domain}."
}

