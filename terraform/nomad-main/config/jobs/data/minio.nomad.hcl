variable "root_username" {
  type = string
}

variable "root_password" {
  type = string
}

variable "version" {
  type = string
}

variable "volume_name" {
  type = string
}

variable "domain" {
  type = string
}

job "minio" {
  namespace   = "data"
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

    volume "data" {
      type            = "csi"
      source          = var.volume_name
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    network {
      mode = "bridge"

      port "s3api" {
        to = 9000
      }

      port "console" {
        to = 9001
      }
    }

    task "minio" {
      driver = "docker"

      config {
        image      = "minio/minio:${var.version}"
        force_pull = true
        args = [
          "server", "/data",
          "--console-address", ":9001"
        ]

        ports = ["s3api", "console"]
      }

      env {
        MINIO_ROOT_USER     = var.root_username
        MINIO_ROOT_PASSWORD = var.root_password
      }

      volume_mount {
        volume      = "data"
        destination = "/data"
      }

      resources {
        cpu    = 256
        memory = 512
      }

      service {
        name     = "minio-s3api"
        provider = "nomad"
        port     = "s3api"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.minio-s3api.rule=Host(`s3.${var.domain}`)",
          "traefik.http.routers.minio-s3api.entrypoints=web",
          "traefik.http.routers.minio-s3api.middlewares=minio-https-redirect",
          "traefik.http.routers.minio-s3api-secure.rule=Host(`s3.${var.domain}`)",
          "traefik.http.routers.minio-s3api-secure.entrypoints=web-secure",
          "traefik.http.routers.minio-s3api-secure.tls=true",
          # Temporarily(?) using the defaultGeneratedCert
          # "traefik.http.routers.minio-s3api-secure.tls.certresolver=letsencrypt",
        ]
      }

      service {
        name     = "minio-console"
        provider = "nomad"
        port     = "console"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.minio.rule=Host(`console.s3.${var.domain}`)",
          "traefik.http.routers.minio.entrypoints=web",
          "traefik.http.routers.minio.middlewares=minio-https-redirect",
          "traefik.http.middlewares.minio-https-redirect.redirectscheme.scheme=https",
          "traefik.http.routers.minio-secure.rule=Host(`console.s3.${var.domain}`)",
          "traefik.http.routers.minio-secure.entrypoints=web-secure",
          "traefik.http.routers.minio-secure.tls=true",
          # Temporarily(?) using the defaultGeneratedCert
          # "traefik.http.routers.minio-secure.tls.certresolver=letsencrypt",
        ]

        check {
          type     = "http"
          path     = "/"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
