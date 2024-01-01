locals {
  inventory = [for i, node in proxmox_vm_qemu.instance[*] : {
    name = node.name
    ip   = local.node_ips[i]
    user = node.ciuser
  }]
}

output "inventory" {
  value = local.inventory
}
