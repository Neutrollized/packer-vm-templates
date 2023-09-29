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

data "amazon-ami" "base_ami" {
  filters = {
    name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
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

source "amazon-ebs" "base-docker" {
  ami_name      = "docker-amd64-base-${local.datestamp}"
  instance_type = "t3a.medium"
  region        = var.region
  source_ami    = data.amazon-ami.base_ami.id
  ssh_username  = "ubuntu"

  tags = {
    Dept = "engineering"
  }
}

build {
  sources = ["sources.amazon-ebs.base-docker"]

  provisioner "shell" {
    expect_disconnect = "true"
    inline = [
      "echo '=============================================='",
      "echo 'APT INSTALL PACKAGES & UPDATES'",
      "echo '=============================================='",
      "sudo apt-get update",
      "sudo apt-get -y install unzip",
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
    expect_disconnect = "true"
    inline = [
      "echo '=============================================='",
      "echo 'ADD DOCKER APT REPO'",
      "echo '=============================================='",
      "sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sleep 15",
      "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\"",
      "sudo reboot"
    ]
  }

  provisioner "shell" {
    inline = [
      "echo '=============================================='",
      "echo 'INSTALL DOCKER'",
      "echo '=============================================='",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io awscli amazon-ecr-credential-helper",
      "sudo systemctl disable docker"
    ]
    pause_before = "10s"
    max_retries  = 5
  }

  provisioner "shell" {
    expect_disconnect = "true"
    inline = [
      "which docker",
      "sudo apt-get clean",
      "echo '=============================================='",
      "echo 'BUILD COMPLETE'",
      "echo '=============================================='"
    ]
  }
}
