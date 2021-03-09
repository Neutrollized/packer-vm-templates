# https://www.packer.io/docs/builders/azure/arm

# you need to declare the variables here so that it knows what to look for in the .pkrvars.hcl var file
variable "client_id" {}
variable "client_secret" {}
variable "subscription_id" {}
variable "tenant_id" {}
variable "managed_image_rg_name" {}
variable "oracle_version" {}
variable "custom_managed_image_name" {}
variable "custom_managed_image_rg_name" {}


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
  managed_image_name                 = "ol7_oracle${var.oracle_version}-${local.datestamp}"
  managed_image_resource_group_name  = var.managed_image_rg_name
  managed_image_storage_account_type = "Premium_LRS"

  os_type                                  = "Linux"
  custom_managed_image_name                = var.custom_managed_image_name
  custom_managed_image_resource_group_name = var.custom_managed_image_rg_name

  azure_tags = {
    dept = "engineering"
  }

  # get list of avail vm sizes in your location:
  # az vm list-sizes --location CanadaCentral
  location = "CanadaCentral"
  vm_size  = "Standard_D2s_v3"
}

build {
  sources = ["sources.azure-arm.oracle-base"]

  provisioner "shell" {
    inline = [
      "sudo yum -y install oracle-database-preinstall-${var.oracle_version}",
      "sudo yum clean all"
    ]
  }

  provisioner "shell" {
    inline = [
      "wget --directory-prefix=/tmp/ https://download.oracle.com/otn-pub/otn_software/db-express/oracle-database-xe-18c-1.0-1.x86_64.rpm",
      "sudo yum -y localinstall /tmp/oracle-database-xe-18c-1.0-1.x86_64.rpm",
      "rm /tmp/oracle-database-xe-18c-1.0-1.x86_64.rpm"
    ]
  }

}
