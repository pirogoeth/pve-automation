#!/usr/bin/env bash

set -uo pipefail

ANSIBLE_VERSION="${ANSIBLE_VERSION:-2.14}"

#######################
# bootstrap-stage0.sh #
#######################
# This script is the first stage of the bootstrap process.
# It should be as light as possible, should be easy to read,
# and should be as infallible as possible.
#
# This script is responsible for:
# - Performing distribution upgrade
# - Installing ansible and bare minimum dependencies

function try_until_success() {
    local command="$@"
    while [ 1 ] ; do
        eval "${command}"
        if [ $? -eq 0 ] ; then
            break
        fi

        sleep 1
    done
}

try_until_success sudo apt update
try_until_success sudo apt dist-upgrade -y

set -x

which python || sudo apt install -y python3 python3-pip pipx
pipx install "ansible-core==${ANSIBLE_VERSION}"

~/.local/bin/ansible --version