output "volume_name" {
  value = nomad_csi_volume.volume.name
}

output "volume_id" {
  value = nomad_csi_volume.volume.id
}

output "volume_namespace" {
  value = nomad_csi_volume.volume.namespace
}
