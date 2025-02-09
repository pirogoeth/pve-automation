resource "nomad_namespace" "continuous_integration" {
  name        = "continuous-integration"
  description = "Continuous integration tooling"
}

# resource "nomad_job" "buildkite-agent" {
#   jobspec    = file("${local.jobs}/continuous-integration/buildkite.nomad.hcl")
# 
#   hcl2 {
#     vars = {
#       token       = var.buildkite_agent_token
#       version     = "3-ubuntu"
#     }
#   }
# }

