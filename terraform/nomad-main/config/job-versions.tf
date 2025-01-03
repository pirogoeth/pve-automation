locals {
  # apps
  coder_version          = "2.7.0"
  miniflux_version       = "2.1.4"
  n8n_version            = "1.71.2"
  plex_version           = "latest"
  ollama_version         = "latest"
  faster_whisper_version = "latest-cuda"
  langfuse_version       = "2"
  handbrake_version      = "latest"

  # data
  changedetectionio_version = "0.47.03"

  # monitoring
  prometheus_version           = "2.53.1"
  grafana_version              = "11.4.0"
  loki_version                 = "3.3.0"
  tempo_version                = "2.6.1"
  vector_version               = "0.34.2-debian"
  nvidia_exporter_version      = "1.2.0"
  qbittorrent_exporter_version = "v1.5.1"

  # security
  falco_version = "0.38.1"

  # system
  cloudflared_version = "2024.12.0"
  traefik_version     = "v3.0.4"
}

