variable "sidekick_version" {
  type = string
}

variable "sidekick_ui_version" {
  type = string
}

variable "redisearch_version" {
  type = string
}

variable "domain" {
  type = string
}

job "falco-sidekick" {
  namespace   = "security"
  type        = "service"
  datacenters = ["dc1"]
  node_pool   = "default"

  update {
    stagger = "30s"
  }

  group "sidekick" {
    count = 1

    network {
      port "http" {
        to = 2801
      }
    }

    task "sidekick" {
      driver = "docker"

      config {
        image = "falcosecurity/falcosidekick:${var.sidekick_version}"
      }
    }
  }

  group "sidekick-ui" {
    count = 1

    task "ui" {
      driver = "docker"

      config {
        image = "falcosecurity/falcosidekick-ui:${var.sidekick_ui_version}"
      }

    }
  }

  group "redisearch" {
    count = 1

    network {
      port "redis" {
        to = 6379
      }
    }

    task "redisearch" {
      driver = "docker"

      config {
        image = "docker.io/redislabs/redisearch:${var.redisearch_version}"
      }
    }
  }
}