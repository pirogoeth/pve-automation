#!/usr/bin/env zsh

#
# ensure-no-plaintext-secrets.sh
#
# Ensures that no cluster secrets are unencrypted.
# Ideally, encrypts them automagically ;)
#
# Expects only to be run in pre-commit mode.

[ ! -z "${HOOK_DEBUG}" ] && set -x

this_script="$(basename $(readlink -fn $0))"
hooks_dir="$(dirname $(readlink -fn $0))"
script_name="${this_script%.*}"

YQ_VERSION=v4.35.1

source "${hooks_dir}/../lib-yq.sh"

[ "$1" != "pre-commit" ] && exit 101

function sops_encrypt() {
    local cleartext_file="$1"
    local secret_dir="$(dirname ${cleartext_file})"
    local hook_config="${secret_dir}/.encrypt_hook.yml"

    local public_key="$(yq '.sops.publicKey' < ${hook_config})"
    local encrypted_regex="$(yq '.sops.encryptedRegex // "^data$"' < ${hook_config})"

    sops --age "${public_key}" \
        --encrypt \
        --encrypted-regex "${encrypted_regex}" \
        --in-place "${cleartext_file}"
}

exitcode=0

find . -name 'secrets' -type d | while read sec_dir
do
    find "${sec_dir}" -regex '.*\.ya?ml' -type f | while read sec_file
    do
        if [[ "$(basename ${sec_file})" == ".encrypt_hook.yml" ]]
        then
            continue
        fi

        values_encrypted=$(yq '[.data | map_values(. | test("^ENC"))] | all' < "${sec_file}")
        if [[ "${values_encrypted}" == "true" ]]
        then
            echo "${sec_file} has all values encrypted"
            continue
        fi

        echo "${sec_file} is not encrypted, fixing.."
        sops_encrypt "${sec_file}"

        exitcode=1
    done
done

exit $exitcode