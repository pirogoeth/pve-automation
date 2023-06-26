# pve-packer

Automated builds for fancy homelab bits.

## Roadmap

- [X] Create a script that will create a barebones Ubuntu Server base inside of PVE to base these builds on
- [X] Plain Docker base image
- [~] Coolify base image
- [~] K3s base image
- [ ] Automated rebuilds? Github Actions? Buildkite?
- [ ] Automated deployments? Flux? ArgoCD?

## Rough Instructions

1. Follow the [packer README](packer/README.md) to create the base images.
2. Follow the [terraform README](terraform/README.md) to create the cluster base.
3. Follow the [ansible README](ansible/README.md) to configure the cluster.