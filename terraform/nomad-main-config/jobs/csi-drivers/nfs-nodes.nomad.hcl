job "plugin-nfs-nodes" {
  namespace   = "csi-drivers"
  datacenters = ["dc1"]
  type        = "system"

  node_pool = "all"

  group "nodes" {
    task "plugin" {
      driver = "docker"
      config {
        image = "mcr.microsoft.com/k8s/csi/nfs-csi:latest"
        args = [
          "--endpoint=unix://csi/csi.sock",
          "--nodeid=${attr.unique.hostname}",
          "--logtostderr",
          "--v=5",
        ]
        privileged = true
      }

      csi_plugin {
        id        = "nfs"
        type      = "node"
        mount_dir = "/csi"
      }

      resources {
        cpu    = 250
        memory = 128
      }
    }
  }
}
