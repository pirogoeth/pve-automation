variable "proxmox_node" {
  description = "Proxmox node to create VMs on."
  type        = string
}

variable "authorized_keys_file" {
  description = "Path to file containing public SSH keys for remoting into nodes."
  type        = string
}

variable "network_gateway" {
  description = "IP address of the network gateway."
  type        = string
  validation {
    # condition     = can(regex("^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}/[0-9]{1,2}$", var.network_gateway))
    condition     = can(regex("^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}$", var.network_gateway))
    error_message = "The network_gateway value must be a valid ip."
  }
}

variable "lan_subnet" {
  description = <<EOF
Subnet used by the LAN network. Note that only the bit count number at the end
is acutally used, and all other subnets provided are secondary subnets.
EOF
  type        = string
  validation {
    condition     = can(regex("^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}/[0-9]{1,2}$", var.lan_subnet))
    error_message = "The lan_subnet value must be a valid cidr range."
  }
}

variable "control_plane_subnet" {
  description = <<EOF
EOF
  type        = string
  validation {
    condition     = can(regex("^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}/[0-9]{1,2}$", var.control_plane_subnet))
    error_message = "The control_plane_subnet value must be a valid cidr range."
  }
}

variable "cluster_name" {
  default     = "k3s"
  type        = string
  description = "Name of the cluster used for prefixing cluster components (ie nodes)."
}

variable "node_templates" {
  type = object({
    leader  = string
    worker  = string
    support = string
  })
  description = <<EOF
Object mapping of node template names to proxmox node template names.
Can be a template VM or plain VM, as long as cloud-init is supported.
EOF
}

variable "proxmox_resource_pool" {
  description = "Resource pool name to use in proxmox to better organize nodes."
  type        = string
  default     = ""
}

variable "support_node_settings" {
  type = object({
    cores        = optional(number, 2),
    sockets      = optional(number, 1),
    memory       = optional(number, 4096),
    storage_type = optional(string, "scsi"),
    storage_id   = optional(string, "local-lvm"),
    disk_size    = optional(string, "10G"),
    extra_disks = optional(list(object({
      size    = string,
      storage = optional(string, "local-lvm"),
      type    = optional(string, "virtio"),
      cache   = optional(string, "none"),
      backup  = optional(number, 0),
    })), []),
    user           = optional(string, "k3s"),
    db_name        = optional(string, "k3s"),
    db_user        = optional(string, "k3s"),
    network_bridge = optional(string, "vmbr0"),
    network_tag    = optional(number, -1),
  })
}

variable "leader_node_count" {
  description = "Number of leader nodes."
  default     = 2
  type        = number
}

variable "leader_node_settings" {
  type = object({
    cores        = optional(number, 2),
    sockets      = optional(number, 1),
    memory       = optional(number, 4096),
    storage_type = optional(string, "scsi"),
    storage_id   = optional(string, "local-lvm"),
    extra_disks = optional(list(object({
      size    = string,
      storage = optional(string, "local-lvm"),
      type    = optional(string, "virtio"),
      cache   = optional(string, "none"),
      backup  = optional(number, 0),
    })), []),
    disk_size      = optional(string, "20G"),
    user           = optional(string, "k3s"),
    network_bridge = optional(string, "vmbr0"),
    network_tag    = optional(number, -1),
  })
}

variable "node_pools" {
  description = "Node pool definitions for the cluster."
  type = list(object({

    name   = string,
    size   = number,
    subnet = string,

    taints = optional(list(string), []),

    cores        = optional(number, 2),
    sockets      = optional(number, 1),
    memory       = optional(number, 4096),
    storage_type = optional(string, "scsi"),
    storage_id   = optional(string, "local-lvm"),
    disk_size    = optional(string, "20G"),
    extra_disks = optional(list(object({
      size    = string,
      storage = optional(string, "local-lvm"),
      type    = optional(string, "virtio"),
      cache   = optional(string, "none"),
      backup  = optional(number, 0),
    })), []),
    user        = optional(string, "k3s"),
    network_tag = optional(number, -1),

    template = optional(string),

    network_bridge = optional(string, "vmbr0"),
  }))
}

variable "api_hostnames" {
  description = "Alternative hostnames for the API server."
  type        = list(string)
  default     = []
}

variable "nameserver" {
  default     = ""
  type        = string
  description = "nameserver"
}

variable "domain_name" {
  description = "Domain base to use for node hostnames"
  type        = string
  default     = "k3s.local"
}
