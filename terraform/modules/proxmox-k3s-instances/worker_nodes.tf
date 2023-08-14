resource "macaddress" "k3s-workers" {
  for_each = local.mapped_worker_nodes
}

locals {
  listed_worker_nodes = flatten([
    for pool in var.node_pools :
    [
      for i in range(pool.size) :
      merge(
        pool,
        { template = coalesce(pool.template, var.node_templates["worker"]) },
        {
          i  = i
          ip = cidrhost(pool.subnet, i)
        },
      )
    ]
  ])

  mapped_worker_nodes = {
    for node in local.listed_worker_nodes : "${node.name}-${node.i}" => node
  }
}

resource "proxmox_vm_qemu" "k3s-worker" {
  depends_on = [
    proxmox_vm_qemu.k3s-support,
    proxmox_vm_qemu.k3s-leader,
  ]

  for_each = local.mapped_worker_nodes

  target_node = var.proxmox_node
  name        = "${var.cluster_name}-${each.key}.${var.domain_name}"
  desc        = "K3s ${var.cluster_name} worker ${each.key}"
  os_type     = "cloud-init"
  agent       = 1

  clone = each.value.template

  pool = var.proxmox_resource_pool

  ciuser     = each.value.user
  sshkeys    = file(var.authorized_keys_file)
  ipconfig0  = "ip=${each.value.ip}/${local.lan_subnet_cidr_bitnum},gw=${var.network_gateway}"
  nameserver = var.nameserver

  cores   = each.value.cores
  sockets = each.value.sockets
  memory  = each.value.memory

  scsihw = "virtio-scsi-pci"
  disk {
    type    = each.value.storage_type
    storage = each.value.storage_id
    size    = each.value.disk_size
  }

  dynamic "disk" {
    for_each = each.value.extra_disks
    content {
      type    = disk.value.type
      storage = disk.value.storage
      size    = disk.value.size
      cache   = disk.value.cache
      backup  = disk.value.backup
    }
  }

  network {
    bridge    = each.value.network_bridge
    firewall  = true
    link_down = false
    macaddr   = upper(macaddress.k3s-workers[each.key].address)
    model     = "virtio"
    queues    = 0
    rate      = 0
    tag       = each.value.network_tag
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
