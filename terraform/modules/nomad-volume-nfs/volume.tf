data "nomad_job" "controller" {
  namespace = "csi-drivers"
  job_id    = "plugin-nfs-controller"
}

data "nomad_job" "node" {
  namespace = "csi-drivers"
  job_id    = "plugin-nfs-nodes"
}

data "nomad_plugin" "nfs" {
  plugin_id        = "nfs"
  wait_for_healthy = true
}

resource "nomad_csi_volume_registration" "volume" {
  external_id = "${var.nfs_host}:${var.nfs_share}"

  plugin_id = data.nomad_plugin.nfs.plugin_id
  volume_id = var.id
  name      = var.name == "" ? var.id : var.name
  namespace = var.namespace

  dynamic "capability" {
    for_each = var.access_modes
    content {
      access_mode     = capability.value
      attachment_mode = "file-system"
    }
  }

  context = {
    server = var.nfs_host
    share  = var.nfs_share
  }

  mount_options {
    fs_type = "nfs"
  }

  depends_on = [
    data.nomad_plugin.nfs,
    data.nomad_job.controller,
    data.nomad_job.node,
  ]
}
