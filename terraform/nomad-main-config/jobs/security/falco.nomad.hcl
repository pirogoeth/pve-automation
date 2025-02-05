variable "version" {
  type = string
}

variable "falco_config" {
  type = string
}

job "falco" {
  namespace   = "security"
  type        = "system"
  datacenters = ["dc1"]
  node_pool   = "all"

  update {
    stagger = "30s"
  }

  group "falco" {
    network {
      port "http" {
        to = 8765
      }
    }

    task "falco" {
      driver = "docker"

      config {
        image = "falcosecurity/falco-no-driver:${var.version}"
        args = [
          "falco", "-c", "${NOMAD_ALLOC_DIR}/falco.yml",
        ]

        ports = ["http"]

        cap_drop = ["ALL"]
        cap_add = [
          "SYS_ADMIN",
          "SYS_RESOURCE",
          "SYS_PTRACE",
        ]

        volumes = [
          "/var/run/docker.sock:/host/var/run/docker.sock",
          "/etc:/host/etc:ro",
          "/proc:/host/proc:ro",
        ]

        labels = {
          appname                  = "falco"
          component                = "scanner"
          vector_stdout_parse_mode = "json"  # stdout: alerts in json format
          vector_stderr_parse_mode = "plain" # stderr: system logs 
        }
      }

      template {
        destination = "${NOMAD_ALLOC_DIR}/falco.yml"
        change_mode = "noop"

        data = var.falco_config
      }

      service {
        provider = "nomad"
        port     = "http"

        tags = [
          "prometheus.io/scrape=true",
          "prometheus.io/path=/metrics"
        ]
      }
    }
  }
}
