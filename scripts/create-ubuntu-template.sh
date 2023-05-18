#!/usr/bin/env bash

this_script=$(basename $0)
this_script=${this_script%.sh}

CLOUD_IMAGES_BASE="https://cloud-images.ubuntu.com"
RELEASE="jammy"
SNAPSHOT="current"
MACHINE_ARCH="amd64"
TARGET_ISO_STORAGE="local"
TARGET_VM_STORAGE="local-lvm"
FORCE=0
VM_DISK_SIZE="16G"
CUSTOM_USER_CONFIG=""
CLEANUP=1

SNIPPETS_STORAGE_PATH="/opt/pve-cloud-init"
SNIPPETS_DIRECTORY="${SNIPPETS_STORAGE_PATH}/snippets"

TMPDIR="$(mktemp -d /tmp/${this_script}.XXXXXX)"
LOGFILE="${TMPDIR}/${this_script}.log"

function usage() {
    echo "Usage: $0 -i <vm_id> [-r <release>] [-s <snapshot>] [-m <machine_arch>] [-t <target_iso_storage>] [-T <target_vm_storage>] [-U <cloud-init user config>] [-F]"
    echo "  -i: VM ID"
    echo "  -n: Node to provision VM on (e.g. pve-001)"
    echo "  -r: Release (default: jammy)"
    echo "  -s: Snapshot (default: current)"
    echo "  -m: Machine architecture (default: amd64)"
    echo "  -t: Target ISO storage (default: local)"
    echo "  -T: Target VM storage (default: local-lvm)"
    echo "  -F: Force image download and/or VM template creation"
    echo "  -C: Skip cleaning up temporary files"
    echo "  -U: PVE storage path to a cloud-init user config file (e.g., local:snippets/users.yml)"
    echo "  -h: Show this help message"
}

function log() {
  msg="[$(date +'%Y-%m-%d %H:%M:%S')] $1"
  echo "${msg}" >>$LOGFILE
  echo "${msg}" >&2
}

function logcapture() {
  cmd="$@"
  log "Running: ${cmd}"
  eval "${cmd}" >>$LOGFILE 2>&1
  return $?
}

function build_image_url() {
  echo "${CLOUD_IMAGES_BASE}/${RELEASE}/${SNAPSHOT}/${RELEASE}-server-cloudimg-${MACHINE_ARCH}.img"
}

function ensure_snippets_storage() {
  logcapture pvesm list "cloud-init"
  if [ $? -ne 0 ] ; then
    log "Creating cloud-init snippet storage"
    logcapture pvesm add dir cloud-init -content snippets -mkdir yes -path "${SNIPPETS_STORAGE_PATH}"
  fi

  write_vendor_snippets
  test -z "${CUSTOM_USER_CONFIG}" && write_default_user_snippets
}

function write_vendor_snippets() {
  cat <<EOF> "${SNIPPETS_DIRECTORY}/vendor-pve-prepare.yml"
#cloud-config

growpart:
  mode: auto
  devices: ["/"]

timezone: Etc/UTC
package_update: true
package_upgrade: true
packages:
  - ca-certificates
  - curl
  - haveged
  - pastebinit
  - pwgen
  - qemu-guest-agent
  - vim-nox
  - wget

runcmd:
  - systemctl enable --now haveged.service
  - systemctl enable --now qemu-guest-agent.service
  - systemctl poweroff
EOF
}

function write_default_user_snippets() {
  cat <<EOF> "${SNIPPETS_DIRECTORY}/users.yml"
#cloud-config
groups:
  - sudo
  - ssh

# Add users to the system. Users are added after groups are added.
# Note: Most of these configuration options will not be honored if the user
#       already exists. Following options are the exceptions and they are
#       applicable on already-existing users:
#       - 'plain_text_passwd', 'hashed_passwd', 'lock_passwd', 'sudo',
#         'ssh_authorized_keys', 'ssh_redirect_user'.
users:
  - default
EOF
}

function check_delete_image() {
  local target_filename="$1"

  # Check if it already exists
  logcapture pvesh get "/nodes/${VM_NODE}/storage/${TARGET_ISO_STORAGE}/content/local:iso/${target_filename}"
  if [ $? -eq 0 ] ; then
    if [ "${FORCE}" == "1" ] ; then
      # Delete the old image first.
      logcapture pvesh delete "/nodes/${VM_NODE}/storage/${TARGET_ISO_STORAGE}/content/local:iso/${target_filename}"
      if [ $? -ne 0 ] ; then
        log "Failed to delete old image, please check the logs and try again."
        return 10
      fi

      return 0
    fi

    log "Image already exists. Skipping download."
    return 1
  fi

  return 0
}

function download_image() {
  local image_url="$1"
  local target_filename="$2"
  log "Using image URL: ${image_url}"

  check_delete_image "${target_filename}"
  case "$?" in
    0) ;;
    1)
      return 0
      ;;
    10)
      exit 1
      ;;
    *)
      log "Unknown return code from check_delete_image!"
      exit 127
      ;;
  esac

  log "Downloading image to: ${TMPDIR}/${target_filename}"
  logcapture curl -sSL -o "${TMPDIR}/${target_filename}" "${image_url}"
  if [ $? -ne 0 ] ; then
    log "Failed to download image, please check the logs and try again."
    exit 1
  fi

  echo "${TMPDIR}/${target_filename}"
}

function check_delete_vm_template() {
  logcapture pvesh get /nodes/${VM_NODE}/qemu/${VM_ID}/status
  case "$?" in
    0)
      if [ "${FORCE}" == "1" ] ; then
        log "Deleting existing VM template: ${VM_ID}"
        logcapture qm set "${VM_ID}" --protection=no
        logcapture qm destroy "${VM_ID}"
        return 0
      else
        log "VM template already exists. Skipping creation."
        return 1
      fi
      ;;
    2)
      # VM template does not exist
      return 0
      ;;
  esac
}

function create_vm_template() {
  local target_filename="$1"
  local target_basename="$(basename ${target_filename%.img})"
  local target_vm_id="${VM_ID}"
  local target_vm_name="${target_basename}-${target_vm_id}"

  check_delete_vm_template "${VM_ID}"
  local check_res=$?
  if [ "${check_res}" -eq "10" ] ; then
    exit 1
  elif [ "${check_res}" -eq "1" ] ; then
    return 0
  fi

  log "Creating VM template: ${target_vm_name}"
  logcapture qm create "${VM_ID}" \
    --cores 2 \
    --memory 2048 \
    --net0 virtio,bridge=vmbr0 \
    --ide2 "${TARGET_VM_STORAGE}:cloudinit" \
    --ostype l26 \
    --numa 1 \
    --ipconfig0 ip=dhcp,ip6=auto \
    --agent enabled=1,freeze-fs-on-backup=1,fstrim_cloned_disks=1,type=virtio \
    --protection 1 \
    --serial0 socket \
    --vga serial0 \
    --name "${target_vm_name}"
  logcapture qm disk import "${VM_ID}" "${target_filename}" "${TARGET_VM_STORAGE}"
  logcapture qm set "${VM_ID}" \
    --scsihw virtio-scsi-pci \
    --scsi0 "${TARGET_VM_STORAGE}:vm-${VM_ID}-disk-0,size=${VM_DISK_SIZE}"
  logcapture qm set "${VM_ID}" \
    --boot c \
    --bootdisk scsi0 \
    --ciuser ubuntu \
    --cicustom "vendor=cloud-init:snippets/vendor-pve-prepare.yml"
  logcapture qm cloudinit update "${VM_ID}"
  # Start the VM to run the prepare script. This will power off the VM when it's done.
  logcapture qm start "${VM_ID}"
  logcapture qm wait "${VM_ID}"

  local ci_user_config="cloud-init:snippets/users.yml"
  if [ ! -z "${CUSTOM_USER_CONFIG}" ] ; then
    ci_user_config="${CUSTOM_USER_CONFIG}"
  fi

  logcapture qm set "${VM_ID}" \
    --ciuser ubuntu \
    --cicustom "user=${ci_user_config}"
  logcapture qm cloudinit update "${VM_ID}"
  logcapture qm template "${VM_ID}"
}

function main() {
  while getopts "i:r:s:m:n:t:T:U:FCh" opt; do
    case $opt in
      i) VM_ID="$OPTARG" ;;
      n) VM_NODE="$OPTARG" ;;
      r) RELEASE="$OPTARG" ;;
      s) SNAPSHOT="$OPTARG" ;;
      m) MACHINE_ARCH="$OPTARG" ;;
      t) TARGET_ISO_STORAGE="$OPTARG" ;;
      T) TARGET_VM_STORAGE="$OPTARG" ;;
      U) CUSTOM_USER_CONFIG="$OPTARG" ;;
      F) FORCE=1 ;;
      C) CLEANUP=0 ;;
      h) usage ; exit 127 ;;
    esac
  done

  if [ -z "${VM_ID}" ] ; then
    echo "VM ID is required"
    usage
    exit 1
  fi

  if [ -z "${VM_NODE}" ] ; then
    echo "VM Node is required"
    usage
    exit 1
  fi

  mkdir -p "${TMPDIR}"
  log "Logging to ${LOGFILE}"

  local image_url="$(build_image_url)"
  local target_filename="${RELEASE}-server-cloudimg-${MACHINE_ARCH}.img"

  ensure_snippets_storage
  image_path=$(download_image "${image_url}" "${target_filename}")
  create_vm_template "${image_path}"

  if [ "${CLEANUP}" == "1" ] ; then
    log "Cleaning up temporary files"
    rm -rfv "${TMPDIR}"
  fi
}

main "$@"