resource "nomad_namespace" "continuous-integration" {
  name        = "continuous-integration"
  description = "Continuous integration tooling"
}

resource "nomad_job" "buildkite-agent" {
  depends_on = [module.buildkite_builds]
  jobspec    = file("${local.jobs}/continuous-integration/buildkite.nomad.hcl")

  hcl2 {
    vars = {
      token       = var.buildkite_agent_token
      version     = "3-ubuntu"
      volume_name = module.buildkite_builds.volume_name
    }
  }
}

