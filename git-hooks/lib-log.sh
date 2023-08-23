LOG_LEVEL="${LOG_LEVEL:-error}"

function log_level::as_num() {
    local level="$(tr '[A-Z]' '[a-z]' <<< $1)"
    case "${level}" in
        debug)
            echo 0
            ;;
        info)
            echo 1
            ;;
        warn)
            echo 2
            ;;
        error)
            echo 3
            ;;
        *)
            echo 1
            ;;
    esac
}

function log() {
    local msg_level="$(tr '[A-Z]' '[a-z]' <<< $1)"
    local app_level_num=$(log_level::as_num "${LOG_LEVEL}")
    local msg_level_num=$(log_level::as_num "${msg_level}")
    if [ "${msg_level_num}" -lt "${app_level_num}" ] ; then
        return 0
    fi

    local msg="[$(date +'%Y-%m-%d %H:%M:%S')] ($msg_level) $2"
    echo "${msg}" >>$LOG_FILE
    echo -e "${msg}" >&2
}

function log::debug() {
    log "debug" "$1"
}

function log::info() {
    log "info" "$1"
}

function log::warn() {
    log "warn" "$1"
}

function log::error() {
    log "error" "$1"
}