variable "version" {
  type = string
}

job "nvidia-exporter" {
  type        = "system"
  datacenters = ["dc1"]
  namespace   = "monitoring"

  node_pool = "gpu"

  update {
    stagger = "30s"
  }

  group "app" {
    count = 1

    network {
      mode = "bridge"

      port "http" {
        to = 9835
      }
    }

    task "nvidia-exporter" {
      driver = "docker"

      config {
        image      = "docker.io/utkuozdemir/nvidia_gpu_exporter:${var.version}"
        force_pull = true

        ports = ["http"]

        volumes = [
          "/usr/bin/nvidia-smi:/usr/bin/nvidia-smi:ro",
          "/usr/lib/x86_64-linux-gnu/libnvidia-ml.so:/usr/lib/x86_64-linux-gnu/libnvidia-ml.so:ro",
          "/usr/lib/x86_64-linux-gnu/libnvidia-ml.so.1:/usr/lib/x86_64-linux-gnu/libnvidia-ml.so.1:ro",
        ]

        devices = [
          {
            host_path          = "/dev/nvidiactl"
            container_path     = "/dev/nvidiactl"
            cgroup_permissions = "rwm"
          },
          {
            host_path          = "/dev/nvidia0"
            container_path     = "/dev/nvidia0"
            cgroup_permissions = "rwm"
          },
          {
            host_path          = "/dev/nvidia1"
            container_path     = "/dev/nvidia1"
            cgroup_permissions = "rwm"
          },
        ]

        labels {
          appname   = "nvidia-exporter"
          component = "nvidia-exporter"
        }
      }

      resources {
        cpu    = 128
        memory = 128
      }

      service {
        provider = "nomad"
        port     = "http"
        tags = [
          "prometheus.io/scrape=true",
          "prometheus.io/path=/metrics",
        ]
      }
    }
  }
}
