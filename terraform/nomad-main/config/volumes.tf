module "changedetection_data" {
  source = "../../modules/nomad-volume-freenas-nfs"

  namespace = "data"
  id        = "changedetection-data"
  capacity = {
    min = "24GiB"
    max = "48GiB"
  }
}

module "miniflux_data" {
  source = "../../modules/nomad-volume-freenas-nfs"

  namespace = "apps"
  id        = "miniflux-data"
  capacity = {
    min = "24GiB"
    max = "48GiB"
  }
}

module "minio_data" {
  source = "../../modules/nomad-volume-freenas-nfs"

  namespace = "data"
  id        = "minio-data"
  capacity = {
    min = "48GiB"
    max = "64GiB"
  }
}

module "buildkite_builds" {
  source = "../../modules/nomad-volume-freenas-nfs"

  namespace   = "continuous-integration"
  id          = "buildkite-builds"
  access_mode = "multi-node-multi-writer"
  capacity = {
    min = "48GiB"
    max = "64GiB"
  }
}
