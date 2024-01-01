job "democratic-csi-storage-node" {
  namespace   = "csi-drivers"
  datacenters = ["dc1"]
  type        = "system"

  group "node" {
    task "node" {
      driver = "docker"

      config {
        image = "democraticcsi/democratic-csi:latest"

        args = [
          "--csi-version=1.2.0",
          "--csi-name=org.democratic-csi.nfs",
          "--driver-config-file=${NOMAD_TASK_DIR}/driver-config-file.yaml",
          "--log-level=debug",
          "--csi-mode=node",
          "--server-socket=/csi-data/csi.sock",
        ]

        privileged = true
      }

      csi_plugin {
        id        = "truenas"
        type      = "node"
        mount_dir = "/csi-data"
      }

      template {
        destination = "${NOMAD_TASK_DIR}/driver-config-file.yaml"

        data = <<EOH
{{with nomadVar "democratic-csi"}}{{.config}}{{end}}
EOH
      }

      resources {
        cpu    = 256
        memory = 256
      }
    }
  }
}
