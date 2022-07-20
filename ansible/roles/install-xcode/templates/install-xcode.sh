#!/bin/sh

set -eu

pushd /Applications >/dev/null

echo "Expanding Xcode XIP ..."
# Although the XIP contains the Xcode version in its name, it always expands to a generic 'Xcode.app' bundle.
xip --expand "{{ xcode_xip_path }}"

echo "Renaming Xcode.app to {{ xcode_name }}"
mv "Xcode.app" "{{ xcode_name }}"

echo "Accepting Xcode license ..."
"./{{ xcode_name }}/Contents/Developer/usr/bin/xcodebuild" -license accept

popd >/dev/null
