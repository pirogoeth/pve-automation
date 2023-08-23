YQ_VERSION="${YQ_VERSION:-4.35.1}"
YQ_STAGING_DIR="${DATA_DIR}/yq"

function yq_download() {
    local bin_path="${YQ_STAGING_DIR}/${YQ_VERSION}"
    if [ -d "${bin_path}" ]
    then
        echo "${bin_path}/yq"
        return 0
    fi

    mkdir -p "${bin_path}"

    local os=$(uname -s | tr '[A-Z]' '[a-z]')
    local arch=amd64
    case "$(uname -m)" in
        x86_64)
            arch=amd64
            ;;
        armv*)
            arch=arm
            ;;
        aarch64)
            arch=arm64
            ;;
    esac

    curl -sL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_${os}_${arch}.tar.gz" \
        | tar xz -C "${bin_path}"
    mv "${bin_path}/yq_${os}_${arch}" "${bin_path}/yq"
    chmod +x "${bin_path}/yq"

    echo "${bin_path}/yq"
}

function yq() {
    local yq_bin=${commands[yq]}
    if test -z ${commands[yq]} ; then
        yq_bin=$(yq_download)
    fi

    "${yq_bin}" "$*"
}