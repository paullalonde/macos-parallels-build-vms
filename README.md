# MacOS Parallels Build VMs

Creates a Parallels Desktop virtual machine containing basic macOS developer tools.
It starts with a *base* VM (see below), and adds the following:

- Homebrew
- Xcode

Installing Xcode, in particular, is enormously time-consuming.
For that reason, this VM doesn't install anything beyond that.
That's left to other VMs that use this one as a base.

#### Base VM

The base VM must have the following characteristics:

- It runs one of the supported versions of macOS (Catalina, Big Sur, or Monterey).
- There's an administrator account called `packer` with a known password.
- Remote Login (i.e. SSH) must be turned on, and enabled for the `packer` account.
- The Command Line Developer Tools are installed.

[This repository](https://github.com/paullalonde/macos-parallels-base-vms) can generate a suitable base VM.

## Requirements

- Packer 1.8
- Parallels Desktop 17
- Parallels Virtualization SDK 17.1.4
- An Xcode XIP file
- A base VM
- jq

## Setup

1. Create a Packer variables file for the version of macOS you are interested in, at `packer/conf/<os>.pkrvars.hcl`.
   Add the following contents:
   ```
   source_vm    = "<REPLACE-ME>"
   ssh_password = "<REPLACE-ME>"
   ```
   Replace the `source_vm`'s value with the path to the base VM.
   Obviously, the base VM has to actually run the correct version of macOS.
   Replace the `ssh_password`'s value with the password of the `packer` account in the VM.

1. (Optional) Edit the Ansible file at `group_vars/<os>.yaml`.
   Edit the following variables:
   ```
   xcode_version = "..."
   ```
   The `xcode_version` variable is the version of Xcode to install.
   It's assumed that the matching XIP file is named `Xcode_{{ xcode_version }}.xip`;
   this is the file's name when downloaded from Apple.

1. Edit the Ansible file at `group_vars/all.yaml`.
   Edit the following variables.
   ```
   xcode_xip_base_url = "..."
   ```
   The `xcode_xip_base_url` variable needs to contain the URL used to reach the Xcode XIP file.
   You need to host this yourself; downloading directly from Apple is unsupported.

## Procedure

1. Run the script:
   ```bash
   ./make-build-vm.sh --os <name>
   ```
   where *name* is one of:
   - `catalina`
   - `bigsur`
   - `monterey`
1. Packer will create the new VM as a copy of the base VM.
1. Packer will then run the Ansible playbook, which in turn installs Homebrew and Xcode.
1. Packer then saves the VM under the `vms` directory.
