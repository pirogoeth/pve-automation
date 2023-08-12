# fluxcd/clusters/main

This directory contains the Flux manifests for the main cluster.

## Secrets

Secrets are encrypted with SOPS (w/ age key) and committed to the repository. To decrypt them, you need to have the SOPS secret key. To decrypt the secrets, run:

```bash
sops -d secrets.yaml > secrets.decrypted.yaml
```

To encrypt the secrets, run:

```bash
sops --age=$(cat secrets/sops-pub.agekey) \
    --encrypt --encrypted-regex '^(data|stringData)$' \
    --in-place secrets/$SECRET_FILE
```

### Initial bootstrapping

[This document](https://web.archive.org/web/20230603204656/https://fluxcd.io/flux/guides/mozilla-sops/) was followed to bootstrap the secrets decryption within the cluster.

### Command history

```bash
$ flux create kustomization pve-automation-secrets --source=pve-automation --path=./fluxcd/clusters/main/secrets --prune=true --interval=10m --decryption-provider=sops --decryption-secret=sops-age
✚ generating Kustomization
► applying Kustomization
✔ Kustomization updated
◎ waiting for Kustomization reconciliation
✔ Kustomization pve-automation-secrets is ready
✔ applied revision main@sha1:978fe3f42761c4377993576e2c9f25bc5ce26079
```

## To-do

- [ ] Need a good, permanent place to store the SOPS key
- [ ] Cluster CSI provisioning
- [ ] What other bootstrap-manifests can be ported into flux now that it's ostensibly ready-to-go?