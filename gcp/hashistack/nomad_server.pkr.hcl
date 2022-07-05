# https://www.packer.io/docs/builders/googlecompute

# you need to declare the variables here so that it knows what to look for in the .pkrvars.hcl var file
variable "project_id" {}
variable "zone" {}
variable "access_token" {}
variable "arch" {}
variable "source_image_family" {}
variable "image_family" {}
variable "nomad_version" {}


locals {
  # https://www.packer.io/docs/templates/hcl_templates/functions/datetime/formatdate
  datestamp = formatdate("YYYYMMDD", timestamp())

  # https://www.packer.io/docs/templates/hcl_templates/functions/string/replace
  # because GCP image name cannot have '.' in its name
  image_nomad_version = replace(var.nomad_version, ".", "-")
}

# https://www.packer.io/docs/builders/googlecompute#required
source "googlecompute" "nomad-server" {
  project_id   = var.project_id
  zone         = var.zone
  machine_type = "n1-standard-1"
  ssh_username = "packer"
  use_os_login = "false"

  # use custom base image that was built
  source_image_family = var.source_image_family

  image_family      = var.image_family
  image_name        = "nomad-${local.image_nomad_version}-${var.arch}-server-${local.datestamp}"
  image_description = "Nomad server image"
}

build {
  sources = ["sources.googlecompute.nomad-server"]

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