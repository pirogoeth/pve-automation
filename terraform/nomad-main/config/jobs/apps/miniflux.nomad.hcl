variable "admin_username" {
  type = string
}

variable "admin_password" {
  type = string
}

variable "domain" {
  type = string
}

variable "version" {
  type    = string
  default = "2.0.51"
}

variable "volume_name" {
  type = string
}

job "miniflux" {
  namespace   = "apps"
  type        = "service"
  datacenters = ["dc1"]

  update {
    max_parallel      = 1
    min_healthy_time  = "10s"
    healthy_deadline  = "3m"
    progress_deadline = "10m"
    auto_revert       = false
    canary            = 0
  }

  group "app" {
    count = 1

    network {
      mode = "bridge"

      port "http" {
        to = 3000
      }
    }

    volume "data" {
      type            = "csi"
      source          = var.volume_name
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "miniflux" {
      driver = "docker"

      config {
        image      = "miniflux/miniflux:${var.version}"
        force_pull = true

        ports = ["http"]

        labels {
          appname                  = "miniflux"
          vector_stderr_parse_mode = "logfmt"
        }
      }

      env {
        DATABASE_URL             = "postgres://miniflux:miniflux@localhost/miniflux?sslmode=disable"
        RUN_MIGRATIONS           = "1"
        CREATE_ADMIN             = "1"
        ADMIN_USERNAME           = var.admin_username
        ADMIN_PASSWORD           = var.admin_password
        LISTEN_ADDR              = ":3000"
        METRICS_COLLECTOR        = "1"
        METRICS_ALLOWED_NETWORKS = "127.0.0.0/8,172.17.0.0/12,10.100.10.0/23"
      }

      resources {
        cpu    = 256
        memory = 256
      }

      service {
        port     = "http"
        provider = "nomad"
        tags = [
          "prometheus.io/scrape=true",
          "prometheus.io/path=/metrics",
          "traefik.enable=true",
          "traefik.http.routers.miniflux.rule=Host(`news.${var.domain}`)",
          "traefik.http.routers.miniflux.entrypoints=web",
          "traefik.http.routers.miniflux.middlewares=miniflux-https-redirect",
          "traefik.http.middlewares.miniflux-https-redirect.redirectscheme.scheme=https",
          "traefik.http.routers.miniflux-secure.rule=Host(`news.${var.domain}`)",
          "traefik.http.routers.miniflux-secure.entrypoints=web-secure",
          "traefik.http.routers.miniflux-secure.tls=true",
          # Temporarily(?) using the defaultGeneratedCert
          # "traefik.http.routers.miniflux-secure.tls.certresolver=letsencrypt",
        ]
      }
    }

    task "postgres" {
      driver = "docker"

      config {
        image      = "postgres:15-alpine"
        force_pull = true
      }

      env {
        POSTGRES_USER     = "miniflux"
        POSTGRES_PASSWORD = "miniflux"
        POSTGRES_DB       = "miniflux"
      }

      volume_mount {
        volume      = "data"
        destination = "/var/lib/postgresql/data"
      }

      resources {
        cpu    = 256
        memory = 256
      }
    }
  }
}
