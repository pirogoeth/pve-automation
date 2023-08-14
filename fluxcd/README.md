# fluxcd

This directory contains the Flux manifests for the main cluster.

## Secrets

Secrets are encrypted with SOPS (w/ age key) and committed to the repository. To decrypt them, you need to have the SOPS secret key. To decrypt the secrets, run:

```bash
sops -d secrets.yaml > secrets.decrypted.yaml
```

To encrypt the secrets, run:

```bash
sops --age=$(cat clusters/main/secrets/sops-pub.agekey) \
    --encrypt --encrypted-regex '^(data|stringData)$' \
    --in-place clusters/main/secrets/$SECRET_FILE
```

### Initial bootstrapping

[This document](https://web.archive.org/web/20230603204656/https://fluxcd.io/flux/guides/mozilla-sops/) was followed to bootstrap the secrets decryption within the cluster.

### Command history

```bash
$ flux bootstrap github --owner=$GITHUB_USER --repository=pve-automation --branch=main --path=./fluxcd --personal
► connecting to github.com
► cloning branch "main" from Git repository "https://github.com/pirogoeth/pve-automation.git"
✔ cloned repository
► generating component manifests
✔ generated component manifests
✔ component manifests are up to date
► installing components in "flux-system" namespace
✔ installed components
✔ reconciled components
► determining if source secret "flux-system/flux-system" exists
► generating source secret
✔ public key: ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBEJaKdmVXGoYaKKE1vsLHEQkIkQhcbbEkgUBjX8YoSAB0FgtZUCJNDy3Tj0GiM7bMyOiaGxWAUSWqPx14JHyLABwMwuK0ZKsCdfeMVUV3J80Ik8QTw5kcZRaod5WIr8HPA==
✔ configured deploy key "flux-system-main-flux-system-./fluxcd" for "https://github.com/pirogoeth/pve-automation"
► applying source secret "flux-system/flux-system"
✔ reconciled source secret
► generating sync manifests
✔ generated sync manifests
✔ sync manifests are up to date
► applying sync manifests
✔ reconciled sync configuration
◎ waiting for Kustomization "flux-system/flux-system" to be reconciled

$ cat clusters/main/secrets/sops.agekey | kubectl create secret generic sops-age --namespace flux-system --from-file=age.agekey=/dev/stdin
secret/sops-age created

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