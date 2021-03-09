# https://www.packer.io/docs/builders/azure/arm

# you need to declare the variables here so that it knows what to look for in the .pkrvars.hcl var file
variable "client_id" {}
variable "client_secret" {}
variable "subscription_id" {}
variable "tenant_id" {}
variable "managed_image_rg_name" {}

locals {
  # https://www.packer.io/docs/templates/hcl_templates/functions/datetime/formatdate
  datestamp = formatdate("YYYYMMDD", timestamp())
}

# create service principal (App registrations in Portal) using:
# az ad sp create-for-rbac --name Packer --query "{ client_id: appId, client_secret: password, tenant_id: tenant }"
source "azure-arm" "oracle-base" {
  client_id       = var.client_id
  client_secret   = var.client_secret
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id

  # will be saved as a managed image rather than in your storage account
  managed_image_name                 = "ol7_base-${local.datestamp}"
  managed_image_resource_group_name  = var.managed_image_rg_name
  managed_image_storage_account_type = "Premium_LRS"

  # get list from:
  # az vm image list --publisher Oracle --offer Oracle-Linux --location CanadaCentral --all
  os_type         = "Linux"
  image_publisher = "Oracle"
  image_offer     = "Oracle-Linux"
  image_sku       = "ol79-lvm"

  communicator = "ssh"
  ssh_timeout  = "30m"

  azure_tags = {
    dept = "engineering"
  }

  # get list of avail vm sizes in your location:
  # az vm list-sizes --location CanadaCentral
  location = "CanadaCentral"
  vm_size  = "Standard_B2s"
}

build {
  sources = ["sources.azure-arm.oracle-base"]

  provisioner "file" {
    destination = "/tmp/"
    source      = "scripts/add_swap.sh"
  }

  provisioner "file" {
    destination = "/tmp/"
    source      = "scripts/add_oracle_fs.sh"
  }

  provisioner "file" {
    destination = "/tmp/"
    source      = "scripts/add_data_fs.sh"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /tmp/add_swap.sh /root/.",
      "sudo mv /tmp/add_oracle_fs.sh /root/.",
      "sudo mv /tmp/add_data_fs.sh /root/."
    ]
  }


  provisioner "shell" {
    inline = [
      "sudo yum -y update"
    ]
  }

  # use "valid_exit_codes" various disconnect error codes
  # even though you put in "expect_disconnect" as that's not 100% reliable 
  provisioner "shell" {
    expect_disconnect   = "true"
    start_retry_timeout = "15m"
    valid_exit_codes    = [0, 143, 2300218]
    inline = [
      "sudo reboot"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo yum -y install compat-libcap1 compat-libstdc++-33",
      "sudo yum clean all"
    ]
  }

}
