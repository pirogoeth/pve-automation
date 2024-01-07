variable "token" {
  type = string
}

variable "version" {
  type    = string
  default = "3-ubuntu"
}

variable "volume_name" {
  type = string
}

job "buildkite" {
  namespace   = "continuous-integration"
  type        = "service"
  datacenters = ["dc1"]

  update {
    stagger      = "10s"
    max_parallel = 1
  }

  group "app" {
    count = 1

    volume "builds" {
      type            = "csi"
      source          = var.volume_name
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    task "agent" {
      driver = "docker"

      config {
        image      = "docker.io/buildkite/agent:${var.version}"
        force_pull = true
        privileged = true

        args = [
          "start", "--token", var.token
        ]

        volumes = [
          # "/usr/local/bin/buildkite-agent:/usr/local/bin/buildkite-agent",
          "/var/run/docker.sock:/var/run/docker.sock",
        ]

        labels {
          appname = "buildkite-agent"
        }
      }

      volume_mount {
        volume      = "builds"
        destination = "/${NOMAD_ALLOC_DIR}/builds"
      }

      env {
        BUILDKITE_BUILD_PATH = "/${NOMAD_ALLOC_DIR}/builds"
      }

      resources {
        cpu    = 128
        memory = 256
      }
    }
  }
}
