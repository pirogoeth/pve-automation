variable "version" {
  type = string
}

job "qbittorrent-exporter" {
  type        = "service"
  datacenters = ["dc1"]
  namespace   = "monitoring"

  node_pool = "all"

  update {
    stagger = "30s"
  }

  group "app" {
    count = 1

    network {
      mode = "bridge"

      port "http" {
        to = 8000
      }
    }

    task "qbittorrent-exporter" {
      driver = "docker"

      config {
        image      = "ghcr.io/esanchezm/prometheus-qbittorrent-exporter:${var.version}"
        force_pull = true

        ports = ["http"]

        labels {
          appname                  = "qbittorrent-exporter"
          component                = "qbittorrent-exporter"
          vector_stdout_parse_mode = "plain"
          vector_stderr_parse_mode = "json"
        }
      }

      env {
        QBITTORRENT_HOST         = "100.97.140.31"
        QBITTORRENT_PORT         = "8080"
        QBITTORRENT_SSL          = "false"
        VERIFY_WEBUI_CERTIFICATE = "false"
      }

      resources {
        cpu    = 128
        memory = 128
      }

      service {
        provider = "nomad"
        port     = "http"
        tags = [
          "prometheus.io/scrape=true",
          "prometheus.io/path=/metrics",
        ]
      }
    }
  }
}
