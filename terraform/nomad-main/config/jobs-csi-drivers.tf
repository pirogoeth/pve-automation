resource "nomad_namespace" "csi_drivers" {
  name        = "csi-drivers"
  description = "CSI driver workloads"
}

# resource "nomad_job" "storage_controller" {
#   jobspec = file("${local.jobs}/csi-drivers/democratic-csi-storage-controller.nomad.hcl")
# }
# 
# resource "nomad_job" "storage_node" {
#   jobspec = file("${local.jobs}/csi-drivers/democratic-csi-storage-node.nomad.hcl")
#   hcl2 {
#     vars = {
#     }
#   }
# }
# 

resource "nomad_job" "nfs_controller" {
  jobspec = file("${local.jobs}/csi-drivers/nfs-controller.nomad.hcl")
}

resource "nomad_job" "nfs_nodes" {
  jobspec = file("${local.jobs}/csi-drivers/nfs-nodes.nomad.hcl")
}