variable "token" {
  type = string
}

variable "version" {
  type    = string
  default = "3-ubuntu"
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
          "/data/buildkite-agent:/data/buildkite-agent",
          "/var/run/docker.sock:/var/run/docker.sock",
        ]

        labels {
          appname = "buildkite-agent"
        }
      }

      env {
        BUILDKITE_BUILD_PATH = "${NOMAD_ALLOC_DIR}/buildkite-agent"
      }

      resources {
        cpu    = 128
        memory = 256
      }
    }
  }
}
