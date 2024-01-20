variable "version" {
  type = string
}

variable "domain" {
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

      template {
        destination     = "local/vector.toml"
        change_mode     = "signal"
        change_signal   = "SIGHUP"
        left_delimiter  = "[[["
        right_delimiter = "]]]"

        data = <<EOF
data_dir = "[[[ env "NOMAD_ALLOC_DIR" ]]]/data"
schema.log_namespace = true

[api]
enabled = true
address = "0.0.0.0:8686"

[sources.host_auth]
type = "file"
include = [
  "/host/var/log/auth.log",
]

[sources.vector_logs]
type = "internal_logs"

[sources.docker]
type = "docker_logs"
include_labels = [
  "appname",
]

[transforms.docker_metadata]
type = "remap"
inputs = ["docker"]
source = """
  parse_mode = "json"
  if %docker_logs.stream == "stderr" {
    parse_mode = downcase(%docker_logs.labels.vector_stderr_parse_mode) ?? "json"
  } else {
    parse_mode = downcase(%docker_logs.labels.vector_stdout_parse_mode) ?? "json"
  }

  if parse_mode == "json" {
    ., .error = parse_json(.message) ?? parse_json(.msg) ?? parse_json(.)
  } else if parse_mode == "logfmt" {
    ., .error = parse_logfmt(.message) ?? parse_logfmt(.msg) ?? parse_logfmt(.)
  } else if parse_mode == "syslog" {
    ., .error = parse_syslog(.message) ?? parse_syslog(.msg) ?? parse_syslog(.)
  } else if parse_mode == "commonlf" {
    ., .error = parse_common_log(.message) ?? parse_common_log(.msg) ?? parse_common_log(.)
  } else if parse_mode == "combinedlf" {
    ., .error = parse_apache_log(.message, format: "combined") ?? parse_apache_log(.msg, format: "combined") ?? parse_apache_log(., format: "combined")
  }

  .appname = %docker_logs.labels.appname
  .metadata = {
    "docker": {
      "image": %docker_logs.image,
      "stream": %docker_logs.stream,
      "container": {
        "id": %docker_logs.container_id,
        "name": %docker_logs.container_name,
      },
    },
    "vector": {
      "parse_mode": parse_mode,
    },
  }
"""

[transforms.host_auth_parser]
type = "remap"
inputs = ["host_auth"]
source = """
  ., .error = parse_linux_authorization(.)
"""

[sinks.loki]
type = "loki"
inputs = ["docker_metadata", "vector_logs", "host_auth_parser"]
endpoint = "https://loki.${var.domain}"
encoding.codec = "json"
labels = { "appname" = "{{appname}}" }

# [sinks.console]
# type = "console"
# inputs = ["docker_metadata", "host_auth_parser"]
# encoding.codec = "json"

[sources.vector_metrics]
type = "internal_metrics"

[sinks.scrape_endpoint]
type = "prometheus_exporter"
inputs = ["vector_metrics"]
address = "0.0.0.0:8687"
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
