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

data "local_file" "docker_manifest" {
  filename = abspath(join("/", [path.module, "..", "..", "manifests", "packer-docker.json"]))
}

locals {
  docker_manifest   = jsondecode(data.local_file.docker_manifest.content)
  last_run_uuid     = local.docker_manifest.last_run_uuid
  last_docker_image = [for build in local.docker_manifest.builds : build if build.packer_run_uuid == local.last_run_uuid][0]
}

module "k3s-main" {
  source = "../modules/proxmox-k3s-instances"

  cluster_name = "k3s-main"

  authorized_keys_file = abspath(join("/", [path.module, "..", "resources", "authorized_keys"]))

  proxmox_node = var.proxmox_node

  node_templates = {
    leader  = local.last_docker_image.custom_data.template_name
    worker  = local.last_docker_image.custom_data.template_name
    support = local.last_docker_image.custom_data.template_name
  }
  proxmox_resource_pool = "k3s-main"
  domain_name           = "c1.2811rrt.net"

  network_gateway = "10.100.10.1"
  lan_subnet      = "10.100.10.0/24"
  nameserver      = "10.100.0.11"

  support_node_settings = {
    cores          = 2
    memory         = 4096
    user           = "ubuntu"
    disk_size      = "25G"
    network_bridge = "vmbr1"
    network_tag    = 20
  }

  leader_node_count = 2
  leader_node_settings = {
    cores          = 2
    memory         = 4096
    user           = "ubuntu"
    disk_size      = "25G"
    network_bridge = "vmbr1"
    network_tag    = 20
  }

  # 10.100.10.248 -> 10.100.10.254 (6 available IPs for control nodes)
  control_plane_subnet = "10.100.10.248/29"

  node_pools = [
    {
      name = "default"
      size = 3
      # 10.100.10.224 -> 10.100.10.239 (14 available IPs for nodes)
      subnet         = "10.100.10.224/28"
      network_bridge = "vmbr1"
      network_tag    = 20
      cores          = 4
      sockets        = 1
      memory         = 4096
      user           = "ubuntu"
      disk_size      = "40G"
      extra_disks = [
        {
          size    = "256G"
          storage = "ext1"
        },
        {
          size    = "256G"
          storage = "ext2"
        },
        {
          size    = "256G"
          storage = "ext3"
        },
      ]
    },
    {
      name = "highmem"
      size = 1
      # 10.100.10.208 -> 10.100.10.223 (14 available IPs for nodes)
      subnet         = "10.100.10.208/28"
      network_bridge = "vmbr1"
      network_tag    = 20
      cores          = 4
      sockets        = 1
      memory         = 16384
      user           = "ubuntu"
      disk_size      = "40G"
      extra_disks = [
        {
          size    = "256G"
          storage = "ext1"
        },
        {
          size    = "256G"
          storage = "ext2"
        },
        {
          size    = "256G"
          storage = "ext3"
        },
      ]
    }
  ]
}

output "k3s_leaders_inventory" {
  value = module.k3s-main.k3s_leaders_inventory
}

output "k3s_workers_inventory" {
  value = module.k3s-main.k3s_workers_inventory
}

output "k3s_support_inventory" {
  value = module.k3s-main.k3s_support_inventory
}

output "postgres_root_password" {
  value     = module.k3s-main.root_db_password
  sensitive = true
}

output "postgres_k3s_password" {
  value     = module.k3s-main.k3s_db_password
  sensitive = true
}

output "k3s_server_token" {
  value     = module.k3s-main.k3s_server_token
  sensitive = true
}
