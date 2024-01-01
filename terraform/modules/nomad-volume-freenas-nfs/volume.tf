data "nomad_job" "controller" {
  namespace = "csi-drivers"
  job_id    = "democratic-csi-storage-controller"
}

data "nomad_job" "node" {
  namespace = "csi-drivers"
  job_id    = "democratic-csi-storage-node"
}

data "nomad_plugin" "truenas" {
  plugin_id        = "truenas"
  wait_for_healthy = true
}

resource "nomad_csi_volume" "volume" {
  plugin_id    = data.nomad_plugin.truenas.plugin_id
  volume_id    = var.id
  name         = var.name == "" ? var.id : var.name
  namespace    = var.namespace
  capacity_min = var.capacity.min
  capacity_max = coalesce(var.capacity.max, var.capacity.min)

  capability {
    access_mode     = var.access_mode
    attachment_mode = "file-system"
  }

  mount_options {
    fs_type = "nfs"
  }

  depends_on = [
    data.nomad_job.controller,
    data.nomad_job.node,
  ]
}
