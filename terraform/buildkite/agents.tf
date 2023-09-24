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

data "local_file" "buildkite_manifest" {
  filename = abspath(join("/", [path.module, "..", "..", "manifests", "packer-buildkite.json"]))
}

locals {
  buildkite_manifest   = jsondecode(data.local_file.buildkite_manifest.content)
  last_run_uuid        = local.buildkite_manifest.last_run_uuid
  last_buildkite_image = [for build in local.buildkite_manifest.builds : build if build.packer_run_uuid == local.last_run_uuid][0]
}

module "agents" {
  source = "../modules/proxmox-buildkite-agents"

  proxmox_node          = var.proxmox_node
  proxmox_resource_pool = "buildkite"

  source_template = local.last_buildkite_image.custom_data.template_name

  authorized_keys_file = abspath(join("/", [path.module, "..", "resources", "authorized_keys"]))

  domain_name = "kite.2811rrt.net"
  nameserver  = "10.100.0.11"

  # 10.100.10.16 -> 10.100.10.31 (14 hosts available)
  subnet          = "10.100.10.16/28"
  network_gateway = "10.100.10.1"

  agent_count = 2
  shape = {
    cores          = 2
    sockets        = 1
    memory         = 4096
    storage_type   = "virtio"
    storage_id     = "local-lvm"
    user           = "buildkite"
    network_bridge = "vmbr1"
    network_tag    = 20

    disk_size = "20G"
    extra_disks = [
      {
        type    = "virtio"
        size    = "100G"
        storage = "ext1"
      },
    ]
  }
}

output "buildkite_inventory" {
  value = module.agents.buildkite_inventory
}
