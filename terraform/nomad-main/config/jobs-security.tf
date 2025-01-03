resource "nomad_namespace" "security" {
  name        = "security"
  description = "System and application security tooling"
}

resource "nomad_job" "falco" {
  jobspec = file("${local.jobs}/security/falco.nomad.hcl")

  hcl2 {
    vars = {
      version      = local.falco_version
      falco_config = file("${local.jobs}/security/falco/config.yml")
    }
  }
}
