variable "nomad_namespaces" {
  type = string
}

variable "version" {
  type    = string
  default = "v2.10.7"
}

job "traefik" {
  datacenters = ["dc1"]
  priority    = 100
  type        = "system"
  namespace   = "nomad-system"

  update {
    max_parallel     = 1
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    canary           = 0
  }

  group "traefik" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    ephemeral_disk {
      sticky  = true
      migrate = true
      size    = 512
    }

    task "traefik" {
      driver = "docker"

      config {
        image      = "traefik:${var.version}"
        force_pull = true

        args = [
          "--configfile=${NOMAD_TASK_DIR}/traefik.yml",
        ]

        labels {
          role = "webserver"
        }

        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock:ro",
        ]
      }

      resources {
        network {
          port "http" {
            static = 80
          }

          port "https" {
            static = 443
          }

          port "traefik-api" {
            static = 8889
          }
        }
      }

      service {
        name = "traefik"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.traefik-api.rule=Host(`traefik.2811rrt.net`) && PathPrefix(`/api`, `/dashboard`)",
          "traefik.http.routers.traefik-api.entrypoints=traefik-api",
          "traefik.http.routers.traefik-api.service=api@internal",
          "traefik.http.routers.traefik-ping.rule=PathPrefix(`/ping`)",
          "traefik.http.routers.traefik-ping.entrypoints=traefik-api",
          "traefik.http.routers.traefik-ping.service=ping@internal",
        ]
        port     = "traefik-api"
        provider = "nomad"

        check {
          name     = "Traefik API Check"
          type     = "http"
          protocol = "http"
          interval = "10s"
          timeout  = "2s"
          path     = "/health"
          method   = "GET"
        }
      }

      template {
        destination = "local/env"
        change_mode = "restart"
        env         = true

        data = <<EOH
{{- with nomadVar "nomad/jobs/traefik" -}}
CF_API_EMAIL="{{ .cloudflareEmail }}"
CF_API_KEY="{{ .cloudflareApiKey }}"
{{- end -}}
EOH
      }

      template {
        destination = "local/nomad-ca-cert.pem"
        change_mode = "signal"

        data = <<EOH
{{ with nomadVar "tls/ca-cert" }}{{ .text }}{{ end }}
EOH
      }

      template {
        destination = "local/nomad-cli-cert.pem"
        change_mode = "signal"

        data = <<EOH
{{ with nomadVar "tls/cli-cert" }}{{ .text }}{{ end }}
EOH
      }

      template {
        destination = "local/nomad-cli-key.pem"
        change_mode = "signal"

        data = <<EOH
{{ with nomadVar "tls/cli-key" }}{{ .text }}{{ end }}
EOH
      }

      template {
        destination = "local/traefik.yml"
        change_mode = "signal"

        data = <<EOH
log:
  level: "DEBUG"
  format: "json"

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: "web-secure"
          scheme: "https"
  web-secure:
    address: ":443"
    http:
      tls: {}
  traefik-api:
    address: ":8889"

certificatesResolvers:
  letsencrypt:
    acme:
      email: "letsencrypt@seanj.dev"
      caServer: "https://acme-v02.api.letsencrypt.org/directory"
      dnsChallenge:
        provider: "cloudflare"
        delayBeforeCheck: 15
        resolvers: ["1.1.1.1:53", "8.8.8.8:53"]

api:
  dashboard: true
  disabledashboardad: true

ping:
  entryPoint: "traefik-api"
  manualRouting: true

metrics:
  prometheus:
    buckets:
      - 0.1
      - 0.3
      - 1.2
      - 5.0
    addEntryPointsLabels: true
    addServicesLabels: true
    addRoutersLabels: true
    entryPoint: "traefik"

providers:
  nomad:
    refreshInterval: "15s"
    endpoint:
      address: "https://{{ env "attr.nomad.advertise.address" }}"
      tls:
        ca: "local/nomad-ca-cert.pem"
        cert: "local/nomad-cli-cert.pem"
        key: "local/nomad-cli-key.pem"
        insecureSkipVerify: true
    exposedByDefault: false
    namespaces: ${var.nomad_namespaces}
EOH
      }
    }
  }
}
