variable "version" {
  type    = string
  default = "main"
}

job "grafana-agent" {
  namespace = "nomad-system"
  type        = "system"
  datacenters = ["dc1"]
  priority    = 90
  node_pool = "all"

  update {
    stagger = "30s"
  }

  group "agent" {
    count = 1

    network {
      mode = "bridge"

      port "http" {
        to = "12345"
      }
    }

    task "grafana-agent" {
      driver = "docker"

      config {
        image      = "grafana/agent:${var.version}"
        force_pull = true

        args = [
          "--server.http.listen-addr=0.0.0.0:12345",
          "${NOMAD_ALLOC_DIR}/config.river",
        ]

        ports = ["http"]

        volumes = [
          "/var/lib/grafana-agent:/var/lib/grafana-agent",
        ]
      }

      template {
        destination = "${NOMAD_ALLOC_DIR}/config.river"
        change_mode = "restart"

        data = <<EOH
logging {
  

}
EOH
      }

      resources {
        cpu    = 128
        memory = 256
      }

      service {
        name     = "grafana-agent"
        port     = "http"
        provider = "nomad"

        check {
          type     = "http"
          path     = "/metrics"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
