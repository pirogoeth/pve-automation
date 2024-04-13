variable "version" {
  type = string
}

variable "domain" {
  type = string
}

variable "vector_config" {
  type = string
}

job "vector" {
  namespace   = "monitoring"
  type        = "system"
  datacenters = ["dc1"]
  node_pool   = "all"

  update {
    stagger      = "30s"
    max_parallel = 1
  }

  group "app" {
    count = 1

    ephemeral_disk {
      sticky  = true
      migrate = true
      size    = 8192
    }

    network {
      port "http" {
        to = 8686
      }

      port "metrics" {
        to = 8687
      }
    }

    task "vector" {
      driver = "docker"

      config {
        image      = "timberio/vector:${var.version}"
        force_pull = true

        args = ["-c", "local/vector.toml"]

        ports = ["http", "metrics"]

        volumes = [
          "/var/log:/host/var/log:ro",
          "/var/run/docker.sock:/var/run/docker.sock",
        ]
      }

      env {
        DOMAIN = "${var.domain}"
      }

      template {
        destination     = "local/vector.toml"
        change_mode     = "signal"
        change_signal   = "SIGHUP"
        left_delimiter  = "[[["
        right_delimiter = "]]]"

        data = <<EOF
${var.vector_config}
EOF
      }

      resources {
        cpu        = 256
        memory     = 256
        memory_max = 512
      }

      service {
        port     = "http"
        provider = "nomad"

        check {
          type     = "http"
          path     = "/health"
          interval = "10s"
          timeout  = "2s"
        }
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
