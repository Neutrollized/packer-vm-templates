# https://www.packer.io/docs/builders/amazon

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
  instance_type = "t4g.micro"
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
      "sudo apt-get update",
      "sudo apt-get -y upgrade",
      "sudo apt-get -y dist-upgrade",
      "sudo apt-get -y autoremove",
      "sudo reboot"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get -y install unzip"
    ]
  }

  provisioner "shell" {
    inline = [
      "git clone https://github.com/Neutrollized/dynmotd.git",
      "cd dynmotd && sudo ./install.sh",
      "cd ~ && rm -Rf ./dynmotd/"
    ]
  }
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
      "wget https://releases.hashicorp.com/consul/${var.consul_version}/consul_${var.consul_version}_linux_${var.arch}.zip",
      "unzip consul_${var.consul_version}_linux_${var.arch}.zip",
      "sudo mv consul /usr/local/bin/",
      "rm consul_${var.consul_version}_linux_${var.arch}.zip"
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
}
