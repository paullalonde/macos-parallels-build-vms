#!/bin/bash

set -eu

mkdir -p output
rm -rf output/*

echo 'Creating tgz archive of VM ...'
tar -czf "output/${TGZ_NAME}" -C build "${PVM_NAME}"

echo 'Computing checksum ...'
pushd output >/dev/null
sha256sum "${TGZ_NAME}" >"${SHA256_NAME}"
touch -r "${TGZ_NAME}" "${SHA256_NAME}"
popd >/dev/null
