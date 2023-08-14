# pve-packer

Automated builds for fancy homelab bits.

## Roadmap

- [X] Create a script that will create a barebones Ubuntu Server base inside of PVE to base these builds on
- [X] Plain Docker base image
- [~] Coolify base image
- [X] K3s base image
- [ ] Automated rebuilds? Github Actions? Buildkite?
- [X] Automated deployments? Flux? ArgoCD?

## Rough Instructions

1. Use `scripts/create-ubuntu-template.sh` to create a barebones Ubuntu Server template.
    - Previously used: `./create-ubuntu-template.sh -i 9001 -n pve-002 -r jammy -s current -m amd64 -t local -T local-lvm -F`
2. Follow the [packer README](packer/README.md) to create the base images.
3. Follow the [terraform README](terraform/README.md) to create the cluster base.
4. Follow the [ansible README](ansible/README.md) to configure the cluster.
5. Follow the [fluxcd README](fluxcd/README.md) to set up gitops.