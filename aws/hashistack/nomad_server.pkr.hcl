# https://www.packer.io/docs/builders/amazon

# you need to declare the variables here so that it knows what to look for in the .pkrvars.hcl var file
variable "owner" {}
variable "region" {}
variable "arch" {}
variable "consul_version" {}
variable "nomad_version" {}
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

source "amazon-ebs" "nomad-server" {
  ami_name      = "nomad-${var.nomad_version}-${var.arch}-server-${local.datestamp}"
  instance_type = "t4g.micro"
  region        = var.region
  source_ami    = data.amazon-ami.base_ami.id
  ssh_username  = "ubuntu"

  tags = {
    Dept = "engineering"
  }
}

build {
  sources = ["sources.amazon-ebs.nomad-server"]

  provisioner "shell" {
    inline = [
      "sudo addgroup --system nomad",
      "sudo adduser --system --ingroup nomad nomad",
      "sudo mkdir -p /etc/nomad.d",
      "sudo mkdir -p /opt/nomad"
    ]
  }

  provisioner "shell" {
    inline = [
      "wget https://releases.hashicorp.com/nomad/${var.nomad_version}/nomad_${var.nomad_version}_linux_${var.arch}.zip",
      "unzip nomad_${var.nomad_version}_linux_${var.arch}.zip",
      "sudo mv nomad /usr/local/bin/",
      "rm nomad_${var.nomad_version}_linux_${var.arch}.zip"
    ]
  }

  provisioner "file" {
    source      = "nomad/20_services_check.sh"
    destination = "/tmp/"
  }

  provisioner "file" {
    source      = "nomad/nomad.service"
    destination = "/tmp/"
  }

  provisioner "file" {
    source      = "nomad/server.hcl"
    destination = "/tmp/"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /tmp/20_services_check.sh /etc/dynmotd.d/",
      "sudo mv /tmp/nomad.service /etc/systemd/system/",
      "sudo systemctl daemon-reload",
      "sudo mv /tmp/server.hcl /etc/nomad.d/",
      "sudo chown -R nomad:nomad /etc/nomad.d",
      "sudo chown -R nomad:nomad /opt/nomad"
    ]
  }
}
