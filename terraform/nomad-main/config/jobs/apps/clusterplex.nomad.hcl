variable "version" {
  type = string
}

variable "domain" {
  type = string
}

variable "volume_name_downloads" {
  type = string
}

variable "volume_name_plex_data" {
  type = string
}

job "clusterplex" {
  type        = "service"
  namespace   = "apps"
  datacenters = ["dc1"]

  node_pool = "all"

  group "orchestrator" {
    volume "downloads" {
      type            = "csi"
      read_only       = false
      source          = var.volume_name_downloads
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    network {
      mode = "bridge"

      port "http" {
        to = 3500
      }
    }

    task "orchestrator" {
      driver = "docker"

      env {
        TZ                        = "America/Chicago"
        LISTENING_PORT            = "3500"
        WORKER_SELECTION_STRATEGY = "LOAD_RANK" # RR | LOAD_CPU | LOAD_TASKS | LOAD_RANK (default)
      }

      config {
        image      = "ghcr.io/pabloromeo/clusterplex_orchestrator:latest"
        force_pull = true

        volumes = [
          "/etc/localtime:/etc/localtime:ro"
        ]

        ports = ["http"]

        labels = {
          appname                  = "clusterplex"
          component                = "orchestrator"
          vector_stdout_parse_mode = "plain"
          vector_stderr_parse_mode = "plain"
        }
      }

      volume_mount {
        volume      = "downloads"
        destination = "/downloads"
        read_only   = false
      }

      resources {
        cpu        = 256
        memory     = 128
        memory_max = 512
      }

      service {
        provider = "nomad"
        port     = "http"
        tags = [
          "prometheus.io/scrape=true",
          "prometheus.io/path=/metrics",

          "traefik.enable=true",
          "traefik.http.routers.clusterplex.rule=Host(`clusterplex.${var.domain}`)",
          "traefik.http.routers.clusterplex.entrypoints=web-secure",
          "traefik.http.routers.clusterplex.tls=true",
          "traefik.http.routers.clusterplex.tls.certresolver=letsencrypt-prod",
        ]

        check {
          type     = "http"
          port     = "http"
          path     = "/health"
          interval = "30s"
          timeout  = "2s"
        }
      }
    }
  }

  group "transcoder" {
    count = 2

    constraint {
      attribute = node.pool
      value     = "gpu"
    }

    update {
      progress_deadline = "20m"
      healthy_deadline  = "15m"
      min_healthy_time  = "30s"
    }

    volume "downloads" {
      type            = "csi"
      read_only       = false
      source          = var.volume_name_downloads
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    volume "plex-data" {
      type            = "csi"
      read_only       = false
      source          = var.volume_name_plex_data
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    network {
      mode = "bridge"
      port "http" {
        to = 3501
      }
    }

    task "transcoder" {
      driver = "docker"

      env {
        DOCKER_MODS       = "ghcr.io/pabloromeo/clusterplex_worker_dockermod:latest"
        VERSION           = "docker"
        PUID              = "65534" # host user `nobody`
        PGID              = "44"    # host group `video`
        TZ                = "America/Chicago"
        LISTENING_PORT    = "3501" # used by the healthcheck
        STAT_CPU_INTERVAL = "2000" # interval for reporting worker load metrics
        EAE_SUPPORT       = "1"
        FFMPEG_HWACCEL    = "cuda"
        HOSTNAME          = "clusterplex-transcode-${NOMAD_ALLOC_INDEX}"
      }

      config {
        image      = "ghcr.io/linuxserver/plex:latest"
        force_pull = true
        runtime    = "nvidia"
        # privileged = true

        group_add = ["video"]

        volumes = [
          "/opt/plex-media/codecs:/codecs",
        ]

        devices = [
          {
            host_path = "/dev/dri"
          }
        ]

        labels = {
          appname                  = "clusterplex"
          component                = "transcoder"
          vector_stdout_parse_mode = "plain"
          vector_stderr_parse_mode = "plain"
        }
      }

      volume_mount {
        volume      = "downloads"
        destination = "/downloads"
        read_only   = false
      }

      # volume_mount {
      #   volume      = "plex-data"
      #   destination = "/config"
      #   read_only   = true
      # }

      template {
        env         = true
        destination = "local/env"
        data        = <<EOH
{{range nomadService "clusterplex-orchestrator-orchestrator"}}
ORCHESTRATOR_URL=http://{{.Address}}:{{.Port}}
{{end}}
EOH
      }

      service {
        provider = "nomad"
        port     = "http"
        tags = [
          "prometheus.io/scrape=true",
          "prometheus.io/path=/metrics",
        ]

        check {
          type     = "http"
          port     = "http"
          path     = "/health"
          interval = "30s"
          timeout  = "2s"
        }
      }

      resources {
        cpu        = 4096
        memory     = 1024
        memory_max = 8192
      }
    }
  }
}
