resource "nomad_namespace" "system" {
  name        = "nomad-system"
  description = "System jobs"
}

resource "nomad_job" "traefik" {
  jobspec = file("${local.jobs}/system/traefik.nomad.hcl")

  hcl2 {
    vars = {
      nomad_namespaces = jsonencode([
        nomad_namespace.apps.name,
        nomad_namespace.data.name,
        nomad_namespace.system.name,
      ])
      version = "v2.10.7"
    }
  }
}
