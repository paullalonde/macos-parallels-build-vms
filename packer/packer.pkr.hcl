packer {
  required_version = "~> 1.8"

  required_plugins {
    parallels = {
      version = ">= 1.0.3"
      source  = "github.com/hashicorp/parallels"
    }
  }
}

variable "base_vm_checksum" {
  description = "The SHA256 checksum of the base VM."
  type        = string
}

variable "base_vm_name" {
  description = "The name of the base VM."
  type        = string
}

variable "base_vm_url" {
  description = "The base URL from which to download the base VM."
  type        = string
}

variable "os_name" {
  description = "The name of version of macOS."
  type        = string
}

variable "ssh_password" {
  description = "The password of the user connecting to the VM via SSH."
  type        = string
  sensitive   = true
}

locals {
  ssh_username = "packer"

  vm_name     = "macos-${var.os_name}-build"
  pvm_name    = "${local.vm_name}.pvm"
  tgz_name    = "${local.pvm_name}.tgz"
  sha256_name = "${local.tgz_name}.sha256"

  base_pvm_name = "${var.base_vm_name}.pvm"
  base_tgz_name = "${local.base_pvm_name}.tgz"
}

# -------------------------------------------------------
# Download phase.

source "file" "bogus" {
  target  = "/dev/null"
  content = "null"
}

build {
  name = "download"

  # A fake source whose only purpose is to allow us to call a provisioner.
  sources = [
    "source.file.bogus",
  ]

  post-processor "shell-local" {
    script = "scripts/download-base-vm.sh"

    env = {
      BASE_VM_URL = var.base_vm_url,
      PVM_NAME    = local.base_pvm_name,
      SHA256      = var.base_vm_checksum,
      TGZ_NAME    = local.base_tgz_name,
    }
  }

  post-processor "artifice" {
    files = [
      "input/${local.base_pvm_name}",
    ]
  }
}

# -------------------------------------------------------
# VM construction phase.

source "parallels-pvm" "main" {
  vm_name              = local.vm_name
  source_path          = "input/${local.base_pvm_name}"
  output_directory     = "build"
  parallels_tools_mode = "disable"
  ssh_username         = local.ssh_username
  ssh_password         = var.ssh_password
  ssh_timeout          = "5m"
  shutdown_command     = "echo '${var.ssh_password}' | sudo -S shutdown -h now"
  shutdown_timeout     = "10m"
  skip_compaction      = true
}

build {
  name = "main"

  sources = [
    "source.parallels-pvm.main",
  ]

  provisioner "ansible" {
    playbook_file = "./ansible/playbook.yaml"
    groups        = [var.os_name]
    user          = local.ssh_username

    extra_arguments = [
      "--extra-vars",
      "ansible_become_pass=${var.ssh_password}",
    ]

    ansible_env_vars = [
      "ANSIBLE_CONFIG=./ansible/ansible.cfg"
    ]
  }

  provisioner "breakpoint" {
    disable = true
    note    = "FILES IN THE INPUT AND BUILD DIRECTORIES WILL BE DELETED AFTER THIS POINT."
  }

  # The VM is built, so we don't need the inputs anymore.
  post-processor "shell-local" {
    inline = [
      "rm -rf input/*"
    ]
  }

  # We don't use the 'compress' post-processor, because its generated tgz isn't satisfactory.
  post-processor "shell-local" {
    script = "scripts/package-vm.sh"

    env = {
      PVM_NAME    = local.pvm_name,
      SHA256_NAME = local.sha256_name,
      TGZ_NAME    = local.tgz_name,
    }
  }

  post-processor "artifice" {
    files = [
      "output/${local.tgz_name}",
      "output/${local.sha256_name}",
    ]
  }

  # The VM is packaged as a tgz under ./output, so we don't need the built VM anymore.
  post-processor "shell-local" {
    inline = [
      "rm -rf build/${local.pvm_name}"
    ]
  }
}
