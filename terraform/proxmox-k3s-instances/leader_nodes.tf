resource "macaddress" "k3s-leaders" {
  count = var.leader_node_count
}

locals {
  leader_node_ips = [for i in range(var.leader_node_count) : cidrhost(var.control_plane_subnet, i + 1)]
}

resource "proxmox_vm_qemu" "k3s-leader" {
  depends_on = [
    proxmox_vm_qemu.k3s-support,
  ]

  count       = var.leader_node_count
  target_node = var.proxmox_node
  name        = "${var.cluster_name}-leader-${count.index}.${var.domain_name}"
  desc        = "K3s ${var.cluster_name} leader node ${count.index}"
  os_type     = "cloud-init"
  agent       = 1

  clone = var.node_templates["leader"]

  pool = var.proxmox_resource_pool

  ciuser     = var.leader_node_settings.user
  sshkeys    = file(var.authorized_keys_file)
  ipconfig0  = "ip=${local.leader_node_ips[count.index]}/${local.lan_subnet_cidr_bitnum},gw=${var.network_gateway}"
  nameserver = var.nameserver

  # cores = 2
  cores   = var.leader_node_settings.cores
  sockets = var.leader_node_settings.sockets
  memory  = var.leader_node_settings.memory

  scsihw = "virtio-scsi-pci"
  disk {
    type    = var.leader_node_settings.storage_type
    storage = var.leader_node_settings.storage_id
    size    = var.leader_node_settings.disk_size
  }

  dynamic "disk" {
    for_each = var.support_node_settings.extra_disks
    content {
      type    = disk.value.type
      storage = disk.value.storage
      size    = disk.value.size
      cache   = disk.value.cache
      backup  = disk.value.backup
    }
  }

  network {
    bridge    = var.leader_node_settings.network_bridge
    firewall  = true
    link_down = false
    macaddr   = upper(macaddress.k3s-leaders[count.index].address)
    model     = "virtio"
    queues    = 0
    rate      = 0
    tag       = var.leader_node_settings.network_tag
  }

  lifecycle {
    ignore_changes = [
      ciuser,
      cicustom,
      sshkeys,
      disk[0],
      network
    ]
  }
}
