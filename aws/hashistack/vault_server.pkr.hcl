# https://www.packer.io/docs/builders/amazon
packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

# you need to declare the variables here so that it knows what to look for in the .pkrvars.hcl var file
variable "owner" {}
variable "region" {}
variable "arch" {}
variable "consul_version" {}
variable "vault_version" {}

data "amazon-ami" "base_ami" {
  filters = {
    name                = "consul-${var.consul_version}-${var.arch}-base-*"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["${var.owner}"]
  region      = var.region
}

locals {
  # https://www.packer.io/docs/templates/hcl_templates/functions/datetime/formatdate
  datestamp = formatdate("YYYYMMDD", timestamp())
}

source "amazon-ebs" "vault-server" {
  ami_name      = "vault-${var.vault_version}-${var.arch}-server-${local.datestamp}"
  instance_type = "t4g.small"
  region        = var.region
  source_ami    = data.amazon-ami.base_ami.id
  ssh_username  = "ubuntu"

  tags = {
    Dept = "engineering"
  }
}

build {
  sources = ["sources.amazon-ebs.vault-server"]

  provisioner "shell" {
    inline = [
      "echo '=============================================='",
      "echo 'CREATE VAULT USER & GROUP'",
      "echo '=============================================='",
      "sudo addgroup --system vault",
      "sudo adduser --system --ingroup vault vault",
      "sudo mkdir -p /etc/vault.d",
      "sudo mkdir -p /opt/vault/raft"
    ]
  }

  provisioner "shell" {
    inline = [
      "echo '=============================================='",
      "echo 'DOWNLOAD VAULT'",
      "echo '=============================================='",
      "wget https://releases.hashicorp.com/vault/${var.vault_version}/vault_${var.vault_version}_linux_${var.arch}.zip",
      "unzip vault_${var.vault_version}_linux_${var.arch}.zip",
      "sudo mv vault /usr/local/bin/",
      "rm vault_${var.vault_version}_linux_${var.arch}.zip"
    ]
    max_retries = 3
  }

  provisioner "file" {
    source      = "vault/20_services_check.sh"
    destination = "/tmp/"
  }

  provisioner "file" {
    source      = "vault/vault.service"
    destination = "/tmp/"
  }

  provisioner "file" {
    source      = "vault/vault.hcl"
    destination = "/tmp/"
  }

  provisioner "shell" {
    inline = [
      "echo '=============================================='",
      "echo 'SETUP VAULT SERVER'",
      "echo '=============================================='",
      "sudo mv /tmp/20_services_check.sh /etc/dynmotd.d/",
      "sudo mv /tmp/vault.service /etc/systemd/system/",
      "sudo systemctl daemon-reload",
      "sudo mv /tmp/vault.hcl /etc/vault.d/",
      "sudo chown -R vault:vault /etc/vault.d",
      "sudo chown -R vault:vault /opt/vault"
    ]
  }

  provisioner "shell" {
    expect_disconnect = "true"
    inline = [
      "which consul",
      "which vault",
      "echo '=============================================='",
      "echo 'BUILD COMPLETE'",
      "echo '=============================================='"
    ]
  }
}
