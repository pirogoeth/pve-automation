variable "version" {
  type = string
}

variable "domain" {
  type = string
}

job "changedetection" {
  namespace   = "data"
  datacenters = ["dc1"]
  type        = "service"

  group "app" {
    count = 1

    network {
      port "http" {
        to = 3000
      }
    }

    task "changedetection" {
      driver = "docker"

      config {
        image      = "ghcr.io/dgtlmoon/changedetection.io:${var.version}"
        force_pull = true

        ports = ["http"]

        labels {
          appname = "changedetection"
        }

        volumes = [
          "/data/changedetection-data:/datastore",
        ]
      }

      env {
        PORT          = NOMAD_PORT_http
        BASE_URL      = "https://changedet.${var.domain}"
        HIDE_REFERER  = "true"
        FETCH_WORKERS = 10
      }

      template {
        destination = "local/env"
        change_mode = "restart"
        env         = true

        data = <<EOF
{{$allocID := env "NOMAD_ALLOC_ID" -}}
{{range nomadService 1 $allocID "changedetection-browser-playwright-chromium"}}
PLAYWRIGHT_DRIVER_URL=ws://{{.Address}}:{{.Port}}/?stealth=1&--disable-web-security=true
{{end}}
EOF
      }

      resources {
        cpu    = 256
        memory = 256
      }

      service {
        port     = "http"
        provider = "nomad"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.changedetection.rule=Host(`changedet.${var.domain}`)",
          "traefik.http.routers.changedetection.entrypoints=web",
          "traefik.http.routers.changedetection.middlewares=changedetection-https-redirect",
          "traefik.http.middlewares.changedetection-https-redirect.redirectscheme.scheme=https",
          "traefik.http.routers.changedetection-secure.rule=Host(`changedet.${var.domain}`)",
          "traefik.http.routers.changedetection-secure.entrypoints=web-secure",
          "traefik.http.routers.changedetection-secure.tls=true",
          # Temporarily(?) using the defaultGeneratedCert
          # "traefik.http.routers.changedetection-secure.tls.certresolver=letsencrypt",
        ]
      }
    }
  }

  group "browser" {
    count = 1

    network {
      port "playwright" {
        to = 3000
      }
    }

    task "playwright-chromium" {
      driver = "docker"

      env {
        SCREEN_WIDTH            = 1920
        SCREEN_HEIGHT           = 1024
        SCREEN_DEPTH            = 16
        ENABLE_DEBUGGER         = false
        PREBOOT_CHROME          = true
        CONNECTION_TIMEOUT      = 300000
        MAX_CONCURRENT_SESSIONS = 2
        CHROME_REFRESH_TIME     = 600000
        DEFAULT_BLOCK_ADS       = true
        DEFAULT_STEALTH         = true
        #             Ignore HTTPS errors, like for self-signed certs
        #           DEFAULT_IGNORE_HTTPS_ERRORS = true
      }

      config {
        image = "browserless/chrome:1.60-chrome-stable"
        ports = ["playwright"]
      }

      resources {
        cpu        = 512
        memory     = 1024
        memory_max = 4096
      }

      service {
        port     = "playwright"
        provider = "nomad"
      }
    }
  }
}
