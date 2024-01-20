variable "s3_endpoint_url" {
  type = string
}

variable "s3_region" {
  type = string
}

variable "s3_bucket_name" {
  type = string
}

variable "s3_access_key_id" {
  type = string
}

variable "s3_secret_access_key" {
  type = string
}

variable "version" {
  type = string
}

variable "domain" {
  type = string
}

job "distribution" {
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

    network {
      mode = "bridge"

      port "http" {
        to = 5000
      }

      port "debug" {
        to = 5001
      }
    }

    task "distribution" {
      driver = "docker"

      config {
        image      = "registry:${var.version}"
        force_pull = true

        ports = ["http", "debug"]
        volumes = [
          "local/config.yml:/etc/docker/registry/config.yml:ro"
        ]

        labels {
          appname                  = "distribution"
          vector_stdout_parse_mode = "combinedlf"
          vector_stderr_parse_mode = "json"
        }
      }

      env {
        REGISTRY_STORAGE_S3_ACCESSKEY      = var.s3_access_key_id
        REGISTRY_STORAGE_S3_SECRETKEY      = var.s3_secret_access_key
        REGISTRY_STORAGE_S3_REGIONENDPOINT = var.s3_endpoint_url
        REGISTRY_STORAGE_S3_REGION         = var.s3_region
        REGISTRY_STORAGE_S3_BUCKET         = var.s3_bucket_name
        REGISTRY_HTTP_ADDR                 = ":5000"
        REGISTRY_HTTP_HOST                 = "oci.${var.domain}"
      }

      template {
        destination = "local/config.yml"
        change_mode = "restart"

        data = <<EOF
---
version: 0.1
log:
  level: info
  formatter: json
http:
  addr: ${REGISTRY_HTTP_ADDR}
  host: ${REGISTRY_HTTP_HOST}
  debug:
    addr: ":5001"
    prometheus:
      enabled: true
      path: /metrics
health:
  storagedriver:
    enabled: true
storage:
  s3:
    accesskey: ${REGISTRY_STORAGE_S3_ACCESSKEY}
    secretkey: ${REGISTRY_STORAGE_S3_SECRETKEY}
    regionendpoint: ${REGISTRY_STORAGE_S3_REGIONENDPOINT}
    bucket: ${REGISTRY_STORAGE_S3_BUCKET}
    encrypt: false
    secure: true
  delete:
    enabled: true
  redirect:
    disable: false
  maintenance:
    uploadpurging:
      enabled: true
      age: 168h
      interval: 24h
      dryrun: false
    readonly:
      enabled: false
EOF
      }

      resources {
        cpu    = 128
        memory = 512
      }

      service {
        port     = "debug"
        provider = "nomad"

        tags = [
          "prometheus.io/scrape=true",
          "prometheus.io/path=/metrics",
          "prometheus.io/scheme=http",
          "prometheus.io/scrape_interval=60s",
        ]
      }

      service {
        port     = "http"
        provider = "nomad"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.distribution.rule=Host(`oci.${var.domain}`)",
          "traefik.http.routers.distribution.entrypoints=web",
          "traefik.http.routers.distribution.middlewares=minio-https-redirect",
          "traefik.http.routers.distribution-secure.rule=Host(`oci.${var.domain}`)",
          "traefik.http.routers.distribution-secure.entrypoints=web-secure",
          "traefik.http.routers.distribution-secure.tls=true",
          # Temporarily(?) using the defaultGeneratedCert
          # "traefik.http.routers.distribution-secure.tls.certresolver=letsencrypt",
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
