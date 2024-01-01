#!/usr/bin/env bash

export NOMAD_TLS_DIR="/opt/nomad/tls"
export NOMAD_ADDR="https://127.0.0.1:4646"
export NOMAD_CACERT="${NOMAD_TLS_DIR}/nomad-agent-ca.pem"
export NOMAD_CLIENT_CERT="${NOMAD_TLS_DIR}/global-cli-nomad.pem"
export NOMAD_CLIENT_KEY="${NOMAD_TLS_DIR}/global-cli-nomad-key.pem"

/usr/local/bin/nomad "$@"