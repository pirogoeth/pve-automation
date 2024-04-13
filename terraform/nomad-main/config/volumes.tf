# `access_mode` notes/docs:
# https://www.nomadproject.io/docs/job-specification/volume#access_mode
#   Defines whether a volume should be available concurrently.
#   The access_mode and attachment_mode together must exactly match one of the volume's capability blocks.
#   Can be one of:
#   - "single-node-reader-only"
#   - "single-node-writer"
#   - "multi-node-reader-only"
#   - "multi-node-single-writer"
#   - "multi-node-multi-writer"
#   Most CSI plugins support only single-node modes.
#   Consult the documentation of the storage provider and CSI plugin.

# module "changedetection_data" {
#   source = "../../modules/nomad-volume-freenas-nfs"
# 
#   namespace = "data"
#   id        = "changedetection-data"
#   capacity = {
#     min = "24GiB"
#     max = "48GiB"
#   }
# }
# 
# module "miniflux_data" {
#   source = "../../modules/nomad-volume-freenas-nfs"
# 
#   namespace = "apps"
#   id        = "miniflux-data"
#   capacity = {
#     min = "24GiB"
#     max = "48GiB"
#   }
# }
# 
# module "minio_data" {
#   source = "../../modules/nomad-volume-freenas-nfs"
# 
#   namespace = "data"
#   id        = "minio-data"
#   capacity = {
#     min = "48GiB"
#     max = "64GiB"
#   }
# }
# 
# module "buildkite_builds" {
#   source = "../../modules/nomad-volume-freenas-nfs"
# 
#   namespace   = "continuous-integration"
#   id          = "buildkite-builds"
#   access_mode = "multi-node-multi-writer"
#   capacity = {
#     min = "48GiB"
#     max = "64GiB"
#   }
# }
# 
# module "prometheus_data" {
#   source = "../../modules/nomad-volume-freenas-nfs"
# 
#   namespace = "monitoring"
#   id        = "prometheus-data"
#   capacity = {
#     min = "128GiB"
#     max = "128GiB"
#   }
# }
# 
# module "n8n_data" {
#   source = "../../modules/nomad-volume-freenas-nfs"
# 
#   namespace = "apps"
#   id        = "n8n-data"
#   capacity = {
#     min = "32GiB"
#     max = "64GiB"
#   }
# }
# 
# module "n8n_local_files" {
#   source = "../../modules/nomad-volume-freenas-nfs"
# 
#   namespace = "apps"
#   id        = "n8n-local-files"
#   capacity = {
#     min = "32GiB"
#     max = "64GiB"
#   }
# }
# 
# module "grafana_data" {
#   source = "../../modules/nomad-volume-freenas-nfs"
# 
#   namespace = "monitoring"
#   id        = "grafana-data"
#   capacity = {
#     min = "32GiB"
#   }
# }
# 
# module "coder_db_data" {
#   source = "../../modules/nomad-volume-freenas-nfs"
# 
#   namespace = "apps"
#   id        = "coder-db-data"
#   capacity = {
#     min = "32GiB"
#   }
# }
# 
# module "whishper_data" {
#   source = "../../modules/nomad-volume-freenas-nfs"
# 
#   namespace = "apps"
#   id        = "whishper-data"
#   capacity = {
#     min = "32GiB"
#   }
# }
# 
# module "whishper_db_data" {
#   source = "../../modules/nomad-volume-freenas-nfs"
# 
#   namespace = "apps"
#   id        = "whishper-db-data"
#   capacity = {
#     min = "32GiB"
#   }
# }
# 
# module "windmill_db_data" {
#   source = "../../modules/nomad-volume-freenas-nfs"
# 
#   namespace = "apps"
#   id        = "windmill-db-data"
#   capacity = {
#     min = "64GiB"
#   }
# }
# 
# module "windmill_worker_cache" {
#   source = "../../modules/nomad-volume-freenas-nfs"
# 
#   namespace   = "apps"
#   id          = "windmill-worker-cache"
#   access_mode = "multi-node-multi-writer"
#   capacity = {
#     min = "64GiB"
#   }
# }
# 
# module "windmill_lsp_cache" {
#   source = "../../modules/nomad-volume-freenas-nfs"
# 
#   namespace = "apps"
#   id = "windmill-lsp-cache"
#   access_mode = "multi-node-multi-writer"
#   capacity = {
#     min = "16GiB"
#   }
# }