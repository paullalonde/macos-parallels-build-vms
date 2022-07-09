packer {
  required_version = "~> 1.8"

  required_plugins {
    parallels = {
      version = ">= 1.0.3"
      source  = "github.com/hashicorp/parallels"
    }
  }
}

variable "os_name" {
  description = "The name of version of macOS."
  type        = string
}

variable "source_vm" {
  description = "The path to the source VM."
  type        = string
}

variable "ssh_password" {
  description = "The password of the user connecting to the VM via SSH."
  type        = string
  sensitive   = true
}

variable "vault_password_file" {
  description = "The path to the file containing the Ansible vault password."
  type        = string
}

locals {
  ssh_username = "packer"
}

source "parallels-pvm" "main" {
  vm_name                = "macos-${var.os_name}-dev"
  source_path            = var.source_vm
  output_directory       = "vms"
  parallels_tools_flavor = "mac"
  ssh_username           = local.ssh_username
  ssh_password           = var.ssh_password
  ssh_timeout            = "5m"
  shutdown_command       = "echo '${var.ssh_password}' | sudo -S shutdown -h now"
  shutdown_timeout       = "10m"
  skip_compaction        = true
}

build {
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
      "--extra-vars",
      "vault-password-file=${var.vault_password_file}",
    ]
  }
}
