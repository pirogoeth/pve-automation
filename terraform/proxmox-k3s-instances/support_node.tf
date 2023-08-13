resource "macaddress" "k3s-support" {}

locals {
  support_node_ip = cidrhost(var.control_plane_subnet, 0)
}

locals {
  lan_subnet_cidr_bitnum = split("/", var.lan_subnet)[1]
}

resource "proxmox_vm_qemu" "k3s-support" {
  target_node = var.proxmox_node
  name        = "${join("-", [var.cluster_name, "support"])}.${var.domain_name}"
  desc        = "K3s ${var.cluster_name} support node"
  os_type     = "cloud-init"
  agent       = 1

  clone = var.node_templates["support"]

  pool = var.proxmox_resource_pool

  ciuser     = var.support_node_settings.user
  sshkeys    = file(var.authorized_keys_file)
  ipconfig0  = "ip=${local.support_node_ip}/${local.lan_subnet_cidr_bitnum},gw=${var.network_gateway}"
  nameserver = var.nameserver

  cores   = var.support_node_settings.cores
  sockets = var.support_node_settings.sockets
  memory  = var.support_node_settings.memory

  scsihw = "virtio-scsi-pci"
  disk {
    type    = var.support_node_settings.storage_type
    storage = var.support_node_settings.storage_id
    size    = var.support_node_settings.disk_size
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
    bridge    = var.support_node_settings.network_bridge
    firewall  = true
    link_down = false
    macaddr   = upper(macaddress.k3s-support.address)
    model     = "virtio"
    queues    = 0
    rate      = 0
    tag       = var.support_node_settings.network_tag
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

locals {
  k3s_server_nodes = [for ip in local.leader_node_ips :
    "${ip}:6443"
  ]
  k3s_worker_nodes = concat(local.leader_node_ips, [
    for node in local.listed_worker_nodes :
    node.ip
  ])
}
