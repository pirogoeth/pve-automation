resource "macaddress" "agent" {
  count = var.agent_count
}

resource "proxmox_vm_qemu" "agent" {
  count = var.agent_count

  target_node = var.proxmox_node
  name        = "${join("-", ["buildkite", count.index])}.${var.domain_name}"
  desc        = "Buildkite agent ${count.index}"
  os_type     = "cloud-init"
  agent       = 1

  clone = var.source_template

  pool = var.proxmox_resource_pool

  ciuser  = var.shape.user
  sshkeys = file(var.authorized_keys_file)
  # TODO: Set up a separate subnet for buildkite agents
  # ipconfig0  = "ip=${local.support_node_ip}/${local.lan_subnet_cidr_bitnum},gw=${var.network_gateway}"
  ipconfig0  = "ip=dhcp,ip6=auto"
  nameserver = var.nameserver

  cores   = var.shape.cores
  sockets = var.shape.sockets
  memory  = var.shape.memory

  scsihw = "virtio-scsi-pci"
  disk {
    type    = var.shape.storage_type
    storage = var.shape.storage_id
    size    = var.shape.disk_size
  }

  dynamic "disk" {
    for_each = var.shape.extra_disks
    content {
      type    = disk.value.type
      storage = disk.value.storage
      size    = disk.value.size
      cache   = disk.value.cache
      backup  = disk.value.backup
    }
  }

  network {
    bridge    = var.shape.network_bridge
    firewall  = true
    link_down = false
    macaddr   = upper(macaddress.agent[count.index].address)
    model     = "virtio"
    queues    = 0
    rate      = 0
    tag       = var.shape.network_tag
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
