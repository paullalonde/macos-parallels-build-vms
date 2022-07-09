#!/bin/bash

set -eu

SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function usage() {
  echo "usage: make-build-vm.sh <options>"                             1>&2
  echo "options:"                                                      1>&2
  echo "  --os <name>  Required. The name of macOS to make a VM for."  1>&2
  echo "               On of: catalina, bigsur, monterey."             1>&2
  exit 20
}

OS=''

while [[ $# -gt 0 ]]
do
  case "$1" in
    --os)
    OS="$2"
    shift
    shift
    ;;

    *)
    usage
  esac
done

if [[ -z "${OS}" ]]; then
  usage
fi

case "${OS}" in
  catalina|bigsur|monterey)
  ;;

  *)
  echo "Unsupported OS '${OS}'." 1>&2
  exit 21
esac

rm -rf "${SELF_DIR}/vms"

pushd "${SELF_DIR}" >/dev/null

PACKER_DIR=packer
PACKER_FILE="${PACKER_DIR}/packer.pkr.hcl"
CONF_FILE="${PACKER_DIR}/conf/${OS}.pkrvars.hcl"

if [[ ! -f "${CONF_FILE}" ]]; then
  echo "Cannot locate Packer variables file '${CONF_FILE}'." 1>&2
  exit 1
fi

packer fmt -check -diff "${PACKER_FILE}"
packer init "${PACKER_FILE}"
packer build \
  -var "os_name=${OS}" \
  -var-file="${CONF_FILE}" \
  "${PACKER_FILE}"

popd >/dev/null
