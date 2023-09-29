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

source "amazon-ebs" "consul-server" {
  ami_name      = "consul-${var.consul_version}-${var.arch}-server-${local.datestamp}"
  instance_type = "t4g.small"
  region        = var.region
  source_ami    = data.amazon-ami.base_ami.id
  ssh_username  = "ubuntu"

  tags = {
    Dept = "engineering"
  }
}

build {
  sources = ["sources.amazon-ebs.consul-server"]

  provisioner "file" {
    source      = "consul/20_services_check.sh"
    destination = "/tmp/"
  }

  provisioner "file" {
    source      = "consul/server.hcl"
    destination = "/tmp/"
  }

  provisioner "shell" {
    inline = [
      "echo '=============================================='",
      "echo 'SETUP CONSUL SERVER'",
      "echo '=============================================='",
      "sudo mv /tmp/20_services_check.sh /etc/dynmotd.d/",
      "sudo mv /tmp/server.hcl /etc/consul.d/",
      "sudo chown -R consul:consul /etc/consul.d"
    ]
  }

  provisioner "shell" {
    expect_disconnect = "true"
    inline = [
      "which consul",
      "echo '=============================================='",
      "echo 'BUILD COMPLETE'",
      "echo '=============================================='"
    ]
  }
}
