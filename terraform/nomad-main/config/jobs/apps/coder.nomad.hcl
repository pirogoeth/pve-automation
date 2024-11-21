variable "version" {
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
        group_add  = ["999"]

        ports = ["http", "metrics"]

        labels {
          appname                  = "coder"
          vector_stdout_parse_mode = "plain"
          vector_stderr_parse_mode = "plain"
        }

        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
        ]
      }

      env {
        CODER_HTTP_ADDRESS                   = "0.0.0.0:7080"
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
          "traefik.enable=true",
          "traefik.http.routers.coder.rule=Host(`code.${var.domain}`)",
          "traefik.http.routers.coder.entrypoints=web-secure",
          "traefik.http.routers.coder.service=coder",
          "traefik.http.routers.coder.tls=true",
          "traefik.http.routers.coder.tls.certresolver=letsencrypt-prod",
          "traefik.http.services.coder.loadbalancer.passhostheader=true",
        ]
      }

      service {
        port     = "metrics"
        provider = "nomad"

        tags = [
          "prometheus.io/scrape=true",
          "prometheus.io/path=/metrics",
        ]
      }

      resources {
        cpu        = 256
        memory     = 512
        memory_max = 2048
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

    task "postgres" {
      driver = "docker"

      config {
        image      = "postgres:15-alpine"
        force_pull = true

        ports = ["postgres"]

        volumes = ["/data/coder-db-postgres:/var/lib/postgresql/data"]
      }

      env {
        POSTGRES_USER     = "coder"
        POSTGRES_PASSWORD = "coder"
        POSTGRES_DB       = "coder"
      }

      resources {
        cpu        = 256
        memory     = 256
        memory_max = 512
      }

      service {
        name     = "coder-postgres"
        port     = "postgres"
        provider = "nomad"
      }
    }
  }
}
