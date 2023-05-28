#!/usr/bin/env bash

# Operates on a Packer manifest to get the artifact ID of the last run.

set -euo pipefail

# If $1 is set, cat the file. Else, use stdin.
if [ -n "${1:-}" ]; then
  input=$(cat "$1")
else
  input=$(cat -)
fi

last=$(jq -r '.last_run_uuid' <<< "$input")
jq -r --arg last "$last" '.builds[] | select(.packer_run_uuid == $last) | .artifact_id' <<< "$input"