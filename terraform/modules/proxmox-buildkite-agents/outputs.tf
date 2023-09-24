locals {
  buildkite_inventory = [for i, node in proxmox_vm_qemu.agent[*] : {
    name = node.name
    ip   = local.node_ips[i]
    user = node.ciuser
  }]
}

output "buildkite_inventory" {
  value = local.buildkite_inventory
}
