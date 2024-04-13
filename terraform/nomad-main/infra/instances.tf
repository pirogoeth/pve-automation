terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.11"
    }

    macaddress = {
      source  = "ivoronin/macaddress"
      version = "0.3.0"
    }
  }
}

provider "proxmox" {
  pm_log_enable = true
  pm_log_file   = "terraform-plugin-proxmox.log"
  pm_debug      = true
  pm_log_levels = {
    _default    = "debug"
    _capturelog = ""
  }

  pm_api_url          = var.proxmox_url
  pm_api_token_id     = var.proxmox_token_id
  pm_api_token_secret = var.proxmox_token_secret
  pm_tls_insecure     = var.proxmox_skip_tls_verify
  pm_parallel         = 1
}

data "local_file" "manifest" {
  filename = abspath(join("/", [path.module, "..", "..", "..", "manifests", "packer-docker.json"]))
}

locals {
  manifest      = jsondecode(data.local_file.manifest.content)
  last_run_uuid = local.manifest.last_run_uuid
  last_image    = [for build in local.manifest.builds : build if build.packer_run_uuid == local.last_run_uuid][0]
}

module "server_instances" {
  source = "../../modules/proxmox-instances"

  proxmox_node          = var.proxmox_node
  proxmox_resource_pool = "nomad-main-2"
  instance_prefix       = "nomad-main-server"
  startup_options       = "order=100,up=30"

  source_template = local.last_image.custom_data.template_name

  authorized_keys_file = abspath(join("/", [path.module, "..", "..", "resources", "authorized_keys"]))

  domain_name = "nm2.2811rrt.net"
  nameserver  = "10.100.0.11"

  # 10.100.10.64 -> 10.100.10.79 (14 hosts available)
  subnet          = "10.100.10.64/28"
  network_gateway = "10.100.10.1"

  instance_count = 3
  shape = {
    cores          = 1
    sockets        = 1
    memory         = 1024 * 2
    storage_type   = "virtio"
    storage_id     = "local-lvm"
    user           = "ubuntu"
    network_bridge = "vmbr1"
    network_tag    = 20

    disk_size = "128G"
  }
  attributes = {
    "nomad_role" = "server"
  }
}


module "client_default_instances" {
  source = "../../modules/proxmox-instances"

  proxmox_node          = var.proxmox_node
  proxmox_resource_pool = "nomad-main-2"
  instance_prefix       = "nomad-main-client"
  startup_options       = "order=100,up=30"

  source_template = local.last_image.custom_data.template_name

  authorized_keys_file = abspath(join("/", [path.module, "..", "..", "resources", "authorized_keys"]))

  domain_name = "nm2.2811rrt.net"
  nameserver  = "10.100.0.11"

  # 10.100.10.32 -> 10.100.10.47 (14 hosts available)
  subnet          = "10.100.10.32/28"
  network_gateway = "10.100.10.1"

  instance_count = 1
  shape = {
    cores          = 8
    sockets        = 1
    memory         = 1024 * 32
    storage_type   = "virtio"
    storage_id     = "local-lvm"
    user           = "ubuntu"
    network_bridge = "vmbr1"
    network_tag    = 20

    disk_size = "128G"
    extra_disks = [
      {
        type    = "virtio"
        size    = "512G"
        storage = "ext1"
      },
      {
        type    = "virtio"
        size    = "512G"
        storage = "ext2"
      },
      {
        type    = "virtio"
        size    = "512G"
        storage = "ext3"
      },
    ]
  }
  attributes = {
    "nomad_role" = "client"
    "nomad_node_pool" = "default"
  }
}

module "client_gpu_instances" {
  source = "../../modules/proxmox-instances"

  proxmox_node          = var.proxmox_node
  proxmox_resource_pool = "nomad-main-2"
  instance_prefix       = "nomad-main-gpu"
  startup_options       = "order=100,up=30"

  source_template = local.last_image.custom_data.template_name

  authorized_keys_file = abspath(join("/", [path.module, "..", "..", "resources", "authorized_keys"]))

  domain_name = "nm2.2811rrt.net"
  nameserver  = "10.100.0.11"

  # 10.100.10.48 -> 10.100.10.63 (14 hosts available)
  subnet          = "10.100.10.48/28"
  network_gateway = "10.100.10.1"

  instance_count = 1
  shape = {
    cores          = 8
    sockets        = 1
    memory         = 1024 * 32
    storage_type   = "virtio"
    storage_id     = "local-lvm"
    user           = "ubuntu"
    network_bridge = "vmbr1"
    network_tag    = 20

    disk_size = "128G"
    extra_disks = [
      {
        type    = "virtio"
        size    = "512G"
        storage = "ext1"
      },
      {
        type    = "virtio"
        size    = "512G"
        storage = "ext2"
      },
      {
        type    = "virtio"
        size    = "512G"
        storage = "ext3"
      },
    ]
  }
  attributes = {
    "nomad_role" = "client"
    "nomad_node_pool" = "gpu"
  }
}

output "nomad_server_inventory" {
  value = module.server_instances.inventory
}

output "nomad_client_inventory" {
  value = concat(
    module.client_default_instances.inventory,
    module.client_gpu_instances.inventory,
  )
}
