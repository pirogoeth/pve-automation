# pve-automation

Fancy homelab automation bits.

## Roadmap

- [X] Create a script that will create a barebones Ubuntu Server base inside of PVE to base these builds on
- [X] Plain Docker base image
- [X] K3s base image
- [X] Buildkite base image
- Packer:
  - [ ] Automated rebuilds? Github Actions? Buildkite?
- K3s:
  - [X] Automated deployments? Flux? ArgoCD?
- Nomad:
  - [ ] Automated deployments???

## Rough Instructions

1. Use `scripts/create-ubuntu-template.sh` to create a barebones Ubuntu Server template.
    - Previously used: `./create-ubuntu-template.sh -i 9001 -n pve-002 -r jammy -s current -m amd64 -t local -T local-lvm -F`
2. Follow the [packer README](packer/README.md) to create the base images.
3. Follow the [terraform README](terraform/README.md) to create the cluster base.
4. Follow the [ansible README](ansible/README.md) to configure the cluster.
5. Follow the [fluxcd README](fluxcd/README.md) to set up gitops.

## Notes (k3s)

- Cluster ingress is handled by [Traefik](https://traefik.io/traefik/), which is a deployment built-in to `k3s`.
- There is a cluster "gateway" of sorts. The `support` node runs the following services:
    - `postgres` (as k3s leader datastore)
    - `pgadmin` (for administrating said postgres)
    - `nginx`
        - TCP proxy load balancer to each cluster node's `traefik` instance
        - Reverse proxying `pgadmin`
        - I have two internal DNS records that point to this node:
            - `gateway.main.k8s.2811rrt.net` - split horizon between Tailnet and my home network
            - `*.main.k8s.2811rrt.net` - CNAME to `gateway.main.k8s.2811rrt.net`
            - Note to self: if you rebuild the cluster, you need to update the Tailnet leg of the split horizon record, as the rebuild changes the instance's Tailnet IP address.

## Notes (nomad)

- Cluster ingress is handled by [Traefik](https://traefik.io/traefik/)
- Jobs are currently deployed via Terraform module, but is unreliable when a full redeploy is needed.
  - A series of targeted applies are needed to get all jobs deployed successfully, but I need to run that down later.