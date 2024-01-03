variable "version" {
  type = string
}

variable "token" {
  type = string
}

job "cloudflared" {
  namespace   = "nomad-system"
  type        = "service"
  datacenters = ["dc1"]

  update {
    stagger = "30s"
  }

  group "app" {
    count = 1

    network {
      port "metrics" {
        to = 3000
      }
    }

    task "cloudflared" {
      driver = "docker"

      config {
        image      = "docker.io/cloudflare/cloudflared:${var.version}"
        force_pull = true

        args = [
          "tunnel",
          "--metrics",
          "0.0.0.0:3000",
          "run",
          "--token",
          var.token,
        ]

        ports = ["metrics"]
      }

      resources {
        cpu    = 256
        memory = 256
      }

      service {
        port     = "metrics"
        provider = "nomad"

        tags = [
          "prometheus.io/scrape=true",
          "prometheus.io/path=/metrics",
        ]
      }
    }
  }
}
