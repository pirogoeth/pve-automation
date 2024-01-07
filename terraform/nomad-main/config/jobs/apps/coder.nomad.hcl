variable "version" {
  type = string
}

variable "volume_name_db_data" {
  type = string
}

variable "domain" {
  type = string
}

job "coder" {
  namespace   = "apps"
  type        = "service"
  datacenters = ["dc1"]

  update {
    max_parallel      = 1
    min_healthy_time  = "10s"
    healthy_deadline  = "3m"
    progress_deadline = "10m"
    auto_revert       = true
    canary            = 0
  }

  group "app" {
    count = 1

    network {
      mode = "bridge"

      port "http" {
        to = 7080
      }

      port "metrics" {
        to = 7081
      }
    }

    task "coder" {
      driver = "docker"

      config {
        image      = "ghcr.io/coder/coder:v${var.version}"
        force_pull = true

        ports = ["http", "metrics"]

        labels {
          appname = "coder"
        }
      }

      env {
        CODER_ADDRESS                        = "0.0.0.0:7080"
        CODER_ACCESS_URL                     = "https://code.${var.domain}"
        CODER_PROMETHEUS_ENABLE              = "true"
        CODER_PROMETHEUS_ADDRESS             = "0.0.0.0:7081"
        CODER_PROMETHEUS_COLLECT_AGENT_STATS = "true"
        CODER_PROMETHEUS_COLLECT_DB_METRICS  = "true"

      }

      template {
        destination = "local/env"
        change_mode = "restart"
        env         = true

        data = <<EOH
{{range nomadService "coder-postgres"}}
CODER_PG_CONNECTION_URL=postgres://coder:coder@{{.Address}}:{{.Port}}/coder?sslmode=disable
{{end}}
EOH
      }

      service {
        port     = "http"
        provider = "nomad"

        tags = [
          "prometheus.io/scrape=true",
          "prometheus.io/path=/metrics",

          "traefik.enable=true",
          "traefik.http.routers.coder.rule=Host(`code.${var.domain}`)",
          "traefik.http.routers.coder.entrypoints=web-secure",
          "traefik.http.routers.coder.service=coder",
          "traefik.http.routers.coder.tls=true",
          "traefik.http.services.coder.loadbalancer.passhostheader=true",
        ]
      }

      resources {
        cpu    = 256
        memory = 512
      }
    }
  }

  group "db" {
    count = 1

    network {
      mode = "bridge"

      port "postgres" {
        to = 5432
      }
    }

    volume "data" {
      type            = "csi"
      source          = var.volume_name_db_data
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "postgres" {
      driver = "docker"

      config {
        image      = "postgres:15-alpine"
        force_pull = true

        ports = ["postgres"]
      }

      env {
        POSTGRES_USER     = "coder"
        POSTGRES_PASSWORD = "coder"
        POSTGRES_DB       = "coder"
      }

      volume_mount {
        volume      = "data"
        destination = "/var/lib/postgresql/data"
      }

      resources {
        cpu    = 256
        memory = 256
      }

      service {
        name     = "coder-postgres"
        port     = "postgres"
        provider = "nomad"
      }
    }
  }
}
