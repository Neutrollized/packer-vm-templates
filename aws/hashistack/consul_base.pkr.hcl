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
    name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-${var.arch}-server-*"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["099720109477"]
  region      = var.region
}

locals {
  # https://www.packer.io/docs/templates/hcl_templates/functions/datetime/formatdate
  datestamp = formatdate("YYYYMMDD", timestamp())
}

source "amazon-ebs" "consul-base" {
  ami_name      = "consul-${var.consul_version}-${var.arch}-base-${local.datestamp}"
  instance_type = "t4g.small"
  region        = var.region
  source_ami    = data.amazon-ami.base_ami.id
  ssh_username  = "ubuntu"

  tags = {
    Dept = "engineering"
  }
}

build {
  sources = ["sources.amazon-ebs.consul-base"]

  provisioner "shell" {
    expect_disconnect = "true"
    inline = [
      "echo '=============================================='",
      "echo 'APT INSTALL PACKAGES & UPDATES'",
      "echo '=============================================='",
      "sudo apt-get update",
      "sudo apt-get -y install git unzip",
      "sudo apt-get -y upgrade",
      "sudo apt-get -y dist-upgrade",
      "sudo apt-get -y autoremove",
      "sudo reboot"
    ]
  }

  provisioner "shell" {
    inline = [
      "echo '=============================================='",
      "echo 'INSTALL DYNMOTD'",
      "echo '=============================================='",
      "git clone https://github.com/Neutrollized/dynmotd.git",
      "cd dynmotd && sudo ./install.sh",
      "cd ~ && rm -Rf ./dynmotd/"
    ]
    pause_before = "10s"
  }

  provisioner "shell" {
    inline = [
      "echo '=============================================='",
      "echo 'CREATE CONSUL USER & GROUP'",
      "echo '=============================================='",
      "sudo addgroup --system consul",
      "sudo adduser --system --ingroup consul consul",
      "sudo mkdir -p /etc/consul.d/ssl",
      "sudo mkdir -p /opt/consul",
      "sudo mkdir -p /var/log/consul"
    ]
  }

  provisioner "shell" {
    inline = [
      "echo '=============================================='",
      "echo 'DOWNLOAD CONSUL'",
      "echo '=============================================='",
      "wget https://releases.hashicorp.com/consul/${var.consul_version}/consul_${var.consul_version}_linux_${var.arch}.zip",
      "unzip consul_${var.consul_version}_linux_${var.arch}.zip",
      "sudo mv consul /usr/local/bin/",
      "rm consul_${var.consul_version}_linux_${var.arch}.zip"
    ]
    max_retries = 3
  }

  provisioner "file" {
    source      = "consul/consul.service"
    destination = "/tmp/"
  }

  provisioner "file" {
    source      = "consul/consul.hcl"
    destination = "/tmp/"
  }

  provisioner "file" {
    source      = "consul/client.hcl"
    destination = "/tmp/"
  }

  provisioner "shell" {
    inline = [
      "echo '=============================================='",
      "echo 'SETUP CONSUL'",
      "echo '=============================================='",
      "sudo mv /tmp/consul.service /etc/systemd/system/",
      "sudo systemctl daemon-reload",
      "sudo mv /tmp/consul.hcl /etc/consul.d/",
      "sudo mv /tmp/client.hcl /etc/consul.d/",
      "sudo chown -R consul:consul /etc/consul.d",
      "sudo chown -R consul:consul /opt/consul",
      "sudo chown -R consul:consul /var/log/consul",
      "sudo chmod 750 /etc/consul.d/ssl"
    ]
  }

  provisioner "shell" {
    expect_disconnect = "true"
    inline = [
      "which consul",
      "sudo apt-get clean",
      "echo '=============================================='",
      "echo 'BUILD COMPLETE'",
      "echo '=============================================='"
    ]
  }
}
