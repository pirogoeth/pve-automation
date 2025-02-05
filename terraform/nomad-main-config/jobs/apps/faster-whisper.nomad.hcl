variable "domain" {
  type = string
}

variable "version" {
  type = string
}

job "faster-whisper" {
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
        to = 8000
      }
    }

    task "faster-whisper" {
      driver = "docker"

      env {
        TZ                     = "America/Chicago"
        NVIDIA_VISIBLE_DEVICES = "all"
      }

      config {
        image              = "fedirz/faster-whisper-server:${var.version}"
        image_pull_timeout = "15m"

        ports = ["whisper-api"]

        volumes = [
          "/data/faster-whisper-data/models:/root/.cache/huggingface",
        ]

        labels = {
          appname                  = "faster-whisper-server"
          component                = "server"
          vector_stdout_parse_mode = "plain"
          vector_stderr_parse_mode = "plain"
        }

        runtime = "nvidia"
      }

      resources {
        cpu        = 500
        memory     = 512
        memory_max = 4096
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
