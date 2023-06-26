locals {
  k3s_leaders_inventory = [for i, node in proxmox_vm_qemu.k3s-leader[*] : {
    name = node.name
    ip   = local.leader_node_ips[i]
    user = node.ciuser
  }]
  k3s_workers_inventory = [for key, node in local.mapped_worker_nodes : {
    name        = proxmox_vm_qemu.k3s-worker[key].name
    ip          = node.ip
    user        = proxmox_vm_qemu.k3s-worker[key].ciuser
    worker_pool = node.name
  }]
  k3s_support_inventory = [{
    name = proxmox_vm_qemu.k3s-support.name
    ip   = local.support_node_ip
    user = proxmox_vm_qemu.k3s-support.ciuser
  }]
}

output "k3s_db_password" {
  value     = random_password.k3s-leader-db-password.result
  sensitive = true
}

output "k3s_db_name" {
  value = var.support_node_settings.db_name
}

output "k3s_db_user" {
  value = var.support_node_settings.db_user
}

output "root_db_password" {
  value     = random_password.support-db-password.result
  sensitive = true
}

output "k3s_server_token" {
  value     = random_password.k3s-server-token.result
  sensitive = true
}

output "k3s_leaders_inventory" {
  value = local.k3s_leaders_inventory
}

output "k3s_workers_inventory" {
  value = local.k3s_workers_inventory
}

output "k3s_support_inventory" {
  value = local.k3s_support_inventory
}
