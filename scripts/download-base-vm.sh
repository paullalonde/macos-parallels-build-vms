#!/bin/bash

set -eu

SHA256_NAME="${TGZ_NAME}.sha256"

mkdir -p input
pushd input >/dev/null

echo 'Downloading base VM archive ...'
curl -fsSL "${BASE_VM_URL}/${TGZ_NAME}" -o "${TGZ_NAME}"

echo 'Verifying checkusm ...'
echo "${SHA256}  ${TGZ_NAME}" >"${SHA256_NAME}"
sha256sum --check "${SHA256_NAME}"

echo 'Extracting base VM from tgz archive ...'
tar -xzf "${TGZ_NAME}" "${PVM_NAME}"

rm -f "${TGZ_NAME}" "${SHA256_NAME}"

popd >/dev/null
