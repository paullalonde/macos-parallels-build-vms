# MacOS Parallels Build VMs

Creates a Parallels Desktop virtual machine containing basic macOS developer tools,
suitable for use as a build machine.
It starts with a *base* VM (see below), and performs the following actions:

- Adds an SSH key for the `packer` account.
- Disables software updates.
- Installs the following software:
  - [Homebrew](https://docs.brew.sh)
  - [jq](https://stedolan.github.io/jq/manual/)
  - Xcode

Installing Xcode, in particular, is enormously time-consuming.
For that reason, this VM doesn't install anything beyond that.
That's left to other VMs that use this one as a base.

## Requirements

- Packer 1.8
- Parallels Desktop 17 (Pro or Business edition, ie $$)
- Parallels Virtualization SDK 17.1.4
- Ansible
- A base VM
- An Xcode XIP file (requires an Apple Developer account).
  This is a cryptographically signed archive of the entire Xcode installation, in an Apple-specific format.
  XIP files for every version of Xcode can be found in the downloads area of the Apple Developer [web site](https:developer.apple.com).

#### Base VM

The base VM must have the following characteristics:

- It runs one of the supported versions of macOS (Catalina, Big Sur, or Monterey).
- There's an administrator account called `packer` with a known password.
- Remote Login (i.e. SSH) must be turned on, and enabled for the `packer` account.
- The Command Line Developer Tools are installed.

The base VM must be named and located according to the following convention:

- The VM is packaged as a tar'd and gzip'd Parallels Desktop VM (`.pvm` extension).
  It's named `${base_vm_url}/${base_vm_name}.pvm.tgz`, where `base_vm_url` and `base_vm_name` are defined below.
- There is also a checksum file, named `${base_vm_url}/${base_vm_name}.pvm.tgz.sha256`,
  which is the output of running `sha256sum` on the tgz file.

[This repository](https://github.com/paullalonde/macos-parallels-base-vms) can generate a suitable base VM.

#### Xcode

Xcode must be named and located according to the following convention:

- The Xcode XIP file is downloaded from this location: `${xcode_xip_base_url}/Xcode_${xcode_version}.xip`.
- The XIP file name (`Xcode_${xcode_version}.xip`) is the file's name when downloaded from Apple.
- The base URL (`${xcode_xip_base_url}`) is used to reach the Xcode XIP file.
  You need to host this yourself; downloading directly from Apple is unsupported.

## Setup

1. Generate an SSH key for the packer account in the VM.
   ```bash
   ssh-keygen
   ```
   The private key needs to be saved somewhere. Don't lose it!

1. Create a Packer variables file for the version of macOS you are interested in, at `packer/conf/<os>.pkrvars.hcl`.
   Add the following variables:
   - `base_vm_checksum` The SHA256 checksum of the base VM.
   - `base_vm_name` The name of the base VM, without any extension.
     Obviously, the base VM has to actually run the correct version of macOS.
   - `base_vm_url` The base URL for downloading the base VM.
   - `ssh_password` The password of the `packer` account in the VM.

1. Edit the Ansible file at `group_vars/all.yaml`.
   Edit the following variables:
     - `xcode_xip_base_url` See above.

1. Edit the Ansible file at `group_vars/<os>.yaml`.
   Edit the following variables:
     - `packer_ssh_public_key` The SSH public key generated in step 1.
     - `xcode_version` (Optional) The version of Xcode to install; see above.

## Procedure

1. Run the script:
   ```bash
   ./make-build-vm.sh --os <name>
   ```
   where *name* is one of:
   - `catalina`
   - `bigsur`
   - `monterey`
1. Packer will the perform the following steps:
   1. Create the new VM as a copy of the base VM.
   1. Run the Ansible playbook, which in turn installs Homebrew and Xcode.
   1. Save the VM.
   1. Tar & gzip the VM, producing a `.tgz` file.
   1. Compute the tgz file's checksum and save it to a file.
1. The final outputs will be:
   - `output/macos-${os_name}-build.pvm.tgz`, the tar'd and gzip'd VM.
   - `output/macos-${os_name}-build.pvm.tgz.sha256`, the checksum.

## Related Repositories

- [Bootable ISO images for macOS](https://github.com/paullalonde/macos-bootable-iso-images).
- [Base VMs for macOS](https://github.com/paullalonde/macos-parallels-base-vms).
