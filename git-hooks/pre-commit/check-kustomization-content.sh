#!/usr/bin/env zsh

#
# check-kustomization-content.sh
#
# Check that all resources are listed in a kustomization.yaml file.
#
# Expects only to be run in pre-commit mode.

[ ! -z "${HOOK_DEBUG}" ] && set -x

this_script="$(basename $(readlink -fn $0))"
hooks_dir="$(dirname $(readlink -fn $0))"
script_name="${this_script%.*}"

YQ_VERSION=v4.35.1

source "${hooks_dir}/../lib-log.sh"
source "${hooks_dir}/../lib-yq.sh"

[ "$1" != "pre-commit" ] && exit 101

function efind() {
    local _path=$1
    shift
    find "${_path}" -regextype 'posix-extended' "$@"
}

exitcode=0

efind . -regex '^.*/kustomization.ya?ml' -type f | while read kustomization
do
    kustomization_dir="$(dirname ${kustomization})"
    log::debug "Checking ${kustomization_dir} for unlisted resources"

    efind "${kustomization_dir}" -type f -regex '^.*\.ya?ml' -and -not -regex '^.*/kustomization\.ya?ml' -and -not -regex '^.*/\..*\.ya?ml' | while read resource
    do
        resource_file="$(basename ${resource})"
        log::debug "Checking ${resource_file} is listed in ${kustomization}"

        if ! grep -q "${resource_file}" "${kustomization}"
        then
            echo "${resource_file} is not listed in ${kustomization}"
            exitcode=1
        fi
    done
done

exit $exitcode
