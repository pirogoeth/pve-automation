#!/usr/bin/env zsh

set -u

this_script=$(readlink -fn $0)
script_mode=$(basename $0)
script_dir="$(dirname $this_script)"
repo_dir="$(dirname $script_dir)"
hook_scripts="${script_dir}/${script_mode}"

SHOW_ALL_HOOKS_OUTPUT="${SHOW_ALL_HOOKS_OUTPUT:-}"
HOOK_DEBUG="${HOOK_DEBUG:-}"
BASE_DATA_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/git-hooks"
export LOG_FILE="${BASE_DATA_DIR}/log.txt"

mkdir -p "${BASE_DATA_DIR}"

source "${script_dir}/lib-log.sh"

log::debug "Git hooks running in ${script_mode} mode"
log::debug "Running scripts from ${hook_scripts}"
log::debug "Base data dir: ${BASE_DATA_DIR}"

success_msg=$(echo -e "\033[48:5:83msuccess\033[0m")
failure_msg=$(echo -e "\033[48:5:160mfailure\033[0m")
error_msg=$(echo -e "\033[48:5:209merror\033[0m")

for script in $(ls ${hook_scripts}/*.sh 2>/dev/null); do
    script_name="$(basename ${script})"
    printf "%-60s" "${script_name}"
    hook_outfile=$(mktemp /tmp/git-hook-${script_name%.*}.XXX)
    (
        cd "${repo_dir}" ; \
        [ ! -z "${HOOK_DEBUG}" ] && set -x \ 
        env \
            DATA_DIR="${BASE_DATA_DIR}/${script_name%.*}" \
            HOOK_DEBUG="${HOOK_DEBUG}" \
            "${script}" "${script_mode}" 2>&1 1>${hook_outfile}
    )
    ec=$?
    case "${ec}" in
        0)
            printf "%20s\n" "[${success_msg}]"
            if [ ! -z "$SHOW_ALL_HOOKS_OUTPUT" ]
            then
                printf -- '-%.0s' $(seq $(tput cols))
                echo
                while read line ; do echo "> ${line}" ; done < ${hook_outfile}
            fi
            ;;
        1)
            printf "%20s\n" "[${failure_msg}]"
            printf -- '-%.0s' $(seq $(tput cols))
            echo
            echo "hook ${script_name} failed. output:"
            echo
            while read line ; do echo "> ${line}" ; done < ${hook_outfile}
            exit 1
            ;;
        101)
            printf "%16s\n" "[${error_msg}]"
            printf -- '-%.0s' $(seq $(tput cols))
            echo
            echo "Unknown exit code: ${ec}"
            exit 1
            ;;
        *)
            printf "%16s\n" "[${error_msg}]"
            printf -- '-%.0s' $(seq $(tput cols))
            echo
            echo "Hook ${script_name} doesn't support mode ${script_mode}"
            exit 1
            ;;
    esac
done