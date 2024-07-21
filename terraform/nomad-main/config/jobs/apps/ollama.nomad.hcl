variable "domain" {
  type = string
}

variable "version" {
  type    = string
  default = "latest"
}

job "ollama" {
  type        = "service"
  namespace   = "apps"
  datacenters = ["dc1"]

  node_pool = "gpu"

  group "app" {
    count = 1

    network {
      mode = "bridge"

      port "http" {
        to = 11434
      }
    }

    task "ollama" {
      driver = "docker"

      config {
        image      = "docker.io/ollama/ollama:${var.version}"
        force_pull = true

        runtime = "nvidia"

        ports = ["http"]

        labels {
          appname                  = "ollama"
          vector_stdout_parse_mode = "plain"
          vector_stderr_parse_mode = "plain"
        }

        volumes = [
          "/etc/localtime:/etc/localtime:ro",
          "/data/ollama-data:/root/.ollama:cached",
        ]
      }

      env {
        TZ                     = "America/Chicago"
        NVIDIA_VISIBLE_DEVICES = "all"
      }

      resources {
        cpu        = 512
        memory     = 128
        memory_max = 10240
      }

      service {
        name     = "ollama"
        provider = "nomad"
        port     = "http"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.ollama.rule=HostRegexp(`ollama.${var.domain}`)",
          "traefik.http.routers.ollama.entrypoints=web-secure",
          "traefik.http.routers.ollama.tls=true",
          "traefik.http.routers.ollama.tls.certresolver=letsencrypt-prod",
        ]

        check {
          type     = "http"
          port     = "http"
          path     = "/"
          interval = "120s"
          timeout  = "2s"
        }
      }
    }
  }
}
