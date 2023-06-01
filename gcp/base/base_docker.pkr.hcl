# https://www.packer.io/docs/builders/googlecompute

# you need to declare the variables here so that it knows what to look for in the .pkrvars.hcl var file
variable "project_id" {}
variable "zone" {}
variable "arch" {}
variable "source_image_family" {}
variable "image_family" {}


locals {
  # https://www.packer.io/docs/templates/hcl_templates/functions/datetime/formatdate
  datestamp = formatdate("YYYYMMDD", timestamp())
}

# https://www.packer.io/docs/builders/googlecompute#required
source "googlecompute" "base-docker" {
  project_id   = var.project_id
  zone         = var.zone
  machine_type = "n1-standard-1"
  ssh_username = "packer"
  use_os_login = "false"

  # gcloud compute images list
  source_image_family = var.source_image_family

  image_family      = var.image_family
  image_name        = "docker-${var.arch}-base-${local.datestamp}"
  image_description = "Debian 11 image with Docker-CE installed"

  tags = ["packer"]
}

build {
  sources = ["sources.googlecompute.base-docker"]

  provisioner "shell" {
    expect_disconnect = "true"
    inline = [
      "echo '=============================================='",
      "echo 'ADD DOCKER APT REPO'",
      "echo 'https://docs.docker.com/engine/install/debian/'",
      "echo '=============================================='",
      "export DEBIAN_FRONTEND=noninteractive",
      "sudo apt-get update",
      "sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release",
      "sudo install -m 0755 -d /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
      "sleep 15",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "echo '=============================================='",
      "echo 'APT INSTALL PACKAGES & UPDATES'",
      "echo '=============================================='",
#      "sudo apt-get update",
#      "sudo apt-get -y install dialog apt-utils git unzip wget",
      "sudo apt-get -y install apt-utils git unzip wget",
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
  }

  provisioner "shell" {
    inline = [
      "echo '=============================================='",
      "echo 'INSTALL DOCKER'",
      "echo '=============================================='",
      "export DEBIAN_FRONTEND=noninteractive",
      "sudo apt-get update",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin",
      "sudo systemctl disable docker"
    ]
  }
}
