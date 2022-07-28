#!/bin/bash

set -eu

SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function usage() {
  echo "usage: make-build-vm.sh <options>"                                 1>&2
  echo "options:"                                                          1>&2
  echo "  --os <name>      Required. The name of macOS to make a VM for."  1>&2
  echo "                   One of: catalina, bigsur, monterey."            1>&2
  echo "  --skip-download  Do not download the VM archive."                1>&2
  exit 20
}

OS=''
DOWNLOAD=1

while [[ $# -gt 0 ]]
do
  case "$1" in
    --os)
    OS="$2"
    shift
    shift
    ;;

    --skip-download)
    DOWNLOAD=''
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
  catalina|monterey)
  OS_NAME="${OS}"
  ;;

  bigsur)
  OS_NAME=big-sur
  ;;

  *)
  echo "Unsupported OS '${OS}'." 1>&2
  exit 21
esac

pushd "${SELF_DIR}" >/dev/null

rm -rf build output

TEMP_DIR=.temp
mkdir -p "${TEMP_DIR}"
rm -rf "${TEMP_DIR}"/*

PACKER_DIR=packer
PACKER_FILE="${PACKER_DIR}/packer.pkr.hcl"
CONF_FILE="${PACKER_DIR}/conf/${OS}.pkrvars.hcl"

if [[ ! -f "${CONF_FILE}" ]]; then
  echo "Cannot locate Packer variables file '${CONF_FILE}'." 1>&2
  exit 2
fi

packer fmt -check -diff "${PACKER_FILE}"
packer init "${PACKER_FILE}"

if [[ -n "${DOWNLOAD}" ]]; then
  rm -rf input

  packer build \
    -only 'download.*' \
    -timestamp-ui \
    -var "os_name=${OS_NAME}" \
    -var-file="${CONF_FILE}" \
    "${PACKER_FILE}"
fi

packer build \
  -only 'main.*' \
  -timestamp-ui \
  -var "os_name=${OS_NAME}" \
  -var-file="${CONF_FILE}" \
  "${PACKER_FILE}"

popd >/dev/null
