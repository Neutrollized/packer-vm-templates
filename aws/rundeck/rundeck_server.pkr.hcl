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
variable "rundeck_version" {}
variable "rundeck_docker_plugin_version" {}

data "amazon-ami" "base_ami" {
  filters = {
    name                = "docker-amd64-base-*"
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

source "amazon-ebs" "rundeck-server" {
  ami_name      = "rundeck-${var.rundeck_version}-amd64-server-${local.datestamp}"
  instance_type = "t3a.medium"
  region        = var.region
  source_ami    = data.amazon-ami.base_ami.id
  ssh_username  = "ubuntu"

  tags = {
    Dept = "engineering"
  }
}


build {
  sources = ["sources.amazon-ebs.rundeck-server"]

  provisioner "shell" {
    inline = [
      "echo '=============================================='",
      "echo 'APT INSTALL JAVA RUNTIME'",
      "echo '=============================================='",
      "echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections",
      "sudo apt-get update",
      "sudo apt-get -y install --no-install-recommends ${var.java_package}",
      "sudo apt-get -y autoremove"
    ]
  }

  provisioner "shell" {
    expect_disconnect = "true"
    inline = [
      "echo '=============================================='",
      "echo 'ADD RUNDECK APT REPO'",
      "echo 'https://docs.rundeck.com/docs/administration/install/linux-deb.html'",
      "echo '=============================================='",
      "sudo install -m 0755 -d /etc/apt/keyrings",
      "echo 'Adding Rundeck GPG key...'",
      "curl -L https://packages.rundeck.com/pagerduty/rundeck/gpgkey | sudo apt-key add -",
      "echo 'Adding Rundeck apt repo...'",
      "echo \"deb https://packages.rundeck.com/pagerduty/rundeck/any/ any main\" | sudo tee /etc/apt/sources.list.d/rundeck.list > /dev/null",
      "echo 'Rebooting...'",
      "sudo reboot"
    ]
  }

  provisioner "shell" {
    expect_disconnect = "true"
    inline = [
      "echo '=============================================='",
      "echo 'INSTALL RUNDECK'",
      "echo '=============================================='",
      "ls /etc/apt/keyrings/",
      "cat /etc/apt/sources.list.d/rundeck.list",
      "sudo apt-get update",
      "sudo apt-get install -y --no-install-recommends rundeck=${var.rundeck_version}",
      "sudo apt-get -y autoremove",
      "sudo systemctl disable rundeck",
      "echo 'Rebooting...'",
      "sudo reboot"
    ]
    pause_before = "10s"
    max_retries  = 5
  }

  provisioner "shell" {
    inline = [
      "echo '=============================================='",
      "echo 'SETUP RUNDECK SERVER'",
      "echo '=============================================='",
      "sudo mv /tmp/rundeckd /etc/default/",
      "sudo mv /tmp/jaas-multiauth.conf /etc/rundeck/",
      "sudo wget https://github.com/rundeck-plugins/docker/releases/download/${var.rundeck_docker_plugin_version}/docker-${var.rundeck_docker_plugin_version}.zip -P /var/lib/rundeck/libext/",
      "sudo chown -R rundeck:rundeck /var/lib/rundeck/user-assets",
      "sudo chown -R rundeck:rundeck /var/lib/rundeck/libext",
      "sudo chown -R rundeck:rundeck /etc/rundeck"
    ]
    pause_before = "10s"
    max_retries  = 3
  }

  provisioner "shell" {
    inline = [
      "echo '=============================================='",
      "echo 'SETUP RUNDECK WORKSPACE'",
      "echo '=============================================='",
      "sudo mkdir -p /rundeck_workspace/.ssh",
      "sudo mkdir -p /rundeck_workspace/ansible-roles",
      "sudo mkdir -p /rundeck_workspace/nomad-jobs",
      "sudo mv /tmp/ansible.cfg /rundeck_workspace",
      "sudo chmod 700 /rundeck_workspace/.ssh",
      "sudo chown -R rundeck /rundeck_workspace"
    ]
  }

  provisioner "shell" {
    expect_disconnect = "true"
    inline = [
      "which java",
      "which rundeck",
      "echo '=============================================='",
      "echo 'BUILD COMPLETE'",
      "echo '=============================================='"
    ]
  }
}
