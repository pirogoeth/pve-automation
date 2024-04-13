variable "domain" {
  type = string
}

variable "version" {
  type = string
}

variable "mongodb_version" {
  type    = string
  default = "6"
}

job "whishper" {
  namespace   = "apps"
  datacenters = ["dc1"]
  type        = "service"

  node_pool = "gpu"

  update {
    stagger = "30s"
  }

  group "app" {
    count = 1

    network {
      port "whisper-api" {
        to = 80
      }

      port "translate-api" {
        to = 5000
      }
    }

    task "mongodb" {
      driver = "docker"

      env {
        MONGO_INITDB_ROOT_USERNAME = "whishper"
        MONGO_INITDB_ROOT_PASSWORD = "whishper"
        MONGO_INITDB_DATABASE      = "whishper"
      }

      config {
        image      = "mongo:${var.mongodb_version}"
        force_pull = true

        args = [
          "--logpath",
          "/var/log/mongodb/mongod.log",
        ]

        volumes = [
          "${NOMAD_ALLOC_DIR}/data/logs:/var/log/mongodb",
          "/data/whishper-db-mongo:/data",
        ]

        labels = {
          appname                  = "whishper"
          component                = "mongodb"
          vector_stdout_parse_mode = "json"
          vector_stderr_parse_mode = "plain"
        }
      }
    }

    task "libretranslate" {
      driver = "docker"

      env {
        LT_DISABLE_WEB_UI = "true"
        LT_LOAD_ONLY      = "en,fr,es"
        LT_UPDATE_MODELS  = "true"
      }

      config {
        image              = "oci.2811rrt.net/libretranslate/libretranslate:latest-cuda"
        image_pull_timeout = "15m"

        ports = ["translate-api"]

        volumes = [
          "${NOMAD_ALLOC_DIR}/data/translate/data:/home/libretranslate/.local/share",
          "${NOMAD_ALLOC_DIR}/data/translate/cache:/home/libretranslate/.local/cache",
          "/data/whishper-libretranslate-cache:${NOMAD_ALLOC_DIR}/data",
        ]

        labels = {
          appname   = "whishper"
          component = "libretranslate"
        }

        runtime = "nvidia"
      }

      resources {
        cpu        = 500
        memory     = 256
        memory_max = 512
      }

      service {
        port     = "translate-api"
        provider = "nomad"
      }
    }

    task "whishper" {
      driver = "docker"

      env {
        PUBLIC_INTERNAL_API_HOST    = "http://127.0.0.1:80"
        PUBLIC_TRANSLATION_API_HOST = "http://127.0.0.1:81"
        PUBLIC_API_HOST             = "whisper.${var.domain}"
        PUBLIC_WHISHPER_PROFILE     = "gpu"
        WHISPER_MODELS_DIR          = "/app/models"
        UPLOAD_DIR                  = "/app/uploads"
      }

      config {
        image              = "oci.2811rrt.net/pluja/whishper:${var.version}"
        image_pull_timeout = "15m"

        ports = ["whisper-api"]

        volumes = [
          "${NOMAD_ALLOC_DIR}/data/whishper/models:/app/models",
          "${NOMAD_ALLOC_DIR}/data/whishper/uploads:/app/uploads",
          "${NOMAD_ALLOC_DIR}/data/whishper/logs:/var/log/whishper",
          "/data/whishper-data:${NOMAD_ALLOC_DIR}/data",
        ]

        labels = {
          appname   = "whishper"
          component = "whishper"
        }

        runtime = "nvidia"
      }

      resources {
        cpu        = 500
        memory     = 256
        memory_max = 512
      }

      service {
        port     = "whisper-api"
        provider = "nomad"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.whisper.rule=HostRegexp(`whisper.${var.domain}`)",
          "traefik.http.routers.whisper.entrypoints=web-secure",
          "traefik.http.routers.whisper.service=whisper",
          "traefik.http.routers.whisper.tls=true",
          # "traefik.http.routers.whisper.tls.certresolver=letsencrypt-prod",
          "traefik.http.services.whisper.loadbalancer.passhostheader=true",
        ]
      }
    }
  }
}
