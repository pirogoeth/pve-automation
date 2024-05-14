output "volume_name" {
  value = nomad_csi_volume_registration.volume.name
}

output "volume_id" {
  value = nomad_csi_volume_registration.volume.id
}

output "volume_namespace" {
  value = nomad_csi_volume_registration.volume.namespace
}
