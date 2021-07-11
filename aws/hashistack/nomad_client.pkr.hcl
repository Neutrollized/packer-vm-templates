# https://www.packer.io/docs/builders/amazon

# you need to declare the variables here so that it knows what to look for in the .pkrvars.hcl var file
variable "owner" {}
variable "region" {}
variable "consul_version" {}
variable "nomad_version" {}

data "amazon-ami" "base_ami" {
  filters = {
    name                = "docker-${var.arch}-base-*"
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

source "amazon-ebs" "nomad-client" {
  ami_name      = "nomad-${var.nomad_version}-amd64-client-${local.datestamp}"
  instance_type = "t3a.small"
  region        = var.region
  source_ami    = data.amazon-ami.base_ami.id
  ssh_username  = "ubuntu"

  tags = {
    Dept = "engineering"
  }
}

build {
  sources = ["sources.amazon-ebs.nomad-client"]

  provisioner "shell" {
    inline = [
      "sudo addgroup --system consul",
      "sudo adduser --system --ingroup consul consul",
      "sudo mkdir -p /etc/consul.d",
      "sudo mkdir -p /opt/consul",
      "sudo mkdir -p /var/log/consul"
    ]
  }

  provisioner "shell" {
    inline = [
      "wget https://releases.hashicorp.com/consul/${var.consul_version}/consul_${var.consul_version}_linux_amd64.zip",
      "unzip consul_${var.consul_version}_linux_amd64.zip",
      "sudo mv consul /usr/local/bin/",
      "rm consul_${var.consul_version}_linux_amd64.zip"
    ]
  }

  provisioner "file" {
    source      = "consul/consul.service"
    destination = "/tmp/"
  }

  provisioner "file" {
    source      = "consul/consul.hcl"
    destination = "/tmp/"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /tmp/consul.service /etc/systemd/system/",
      "sudo systemctl daemon-reload",
      "sudo mv /tmp/consul.hcl /etc/consul.d/",
      "sudo chown -R consul:consul /etc/consul.d",
      "sudo chown -R consul:consul /opt/consul",
      "sudo chown -R consul:consul /var/log/consul"
    ]
  }

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
      "wget https://releases.hashicorp.com/nomad/${var.nomad_version}/nomad_${var.nomad_version}_linux_amd64.zip",
      "unzip nomad_${var.nomad_version}_linux_amd64.zip",
      "sudo mv nomad /usr/local/bin/",
      "rm nomad_${var.nomad_version}_linux_amd64.zip"
    ]
  }

  provisioner "file" {
    source      = "nomad/nomad.service"
    destination = "/tmp/"
  }

  provisioner "file" {
    source      = "nomad/client.hcl"
    destination = "/tmp/"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /tmp/nomad.service /etc/systemd/system/",
      "sudo systemctl daemon-reload",
      "sudo mv /tmp/client.hcl /etc/nomad.d/",
      "sudo chown -R nomad:nomad /etc/nomad.d",
      "sudo chown -R nomad:nomad /opt/nomad"
    ]
  }

  provisioner "file" {
    source      = "nomad/ecr-config.json"
    destination = "/tmp/"
  }

  provisioner "shell" {
    inline = [
      "sudo mkdir -p /root/.docker/",
      "sudo mv /tmp/ecr-config.json /root/.docker/"
    ]
  }
}
