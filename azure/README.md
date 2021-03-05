# README
Before you can begin to build with Packer on Azure, you will need to create a service principal with `client_id` and `client_secret`.  You can do that either from the Portal (except if you won't find "service principals", you create them under "App registrations"...) or you can create them from command-line:

`az ad sp create-for-rbac --name Packer --query "{ client_id: appId, client_secret: password, tenant_id: tenant }"

## Useful `az` commands
- [`az vm image list`](https://docs.microsoft.com/en-us/cli/azure/vm/image?view=azure-cli-latest#az_vm_image_list)
- [`az vm list-sizes`](https://docs.microsoft.com/en-us/cli/azure/vm?view=azure-cli-latest#az_vm_list_sizes)

## Sample usage
`packer build -var-file=variables.pkrvars.hcl ol7_base.pkr.hcl`

where my **variables.pkrvars.hcl** file would be something like:
```
oracle_version = "18c"

client_id       = "abcdefgh-1234-5678-9012-abcdefghijkl"
client_secret   = "mySup3rS3cre7!"
subscription_id = "12345678-abcd-efgh-ijkl-1234567890ab"
tenant_id       = "zyxwvuts-9876-5432-1098-zyxwvutsrqpo"

managed_image_resource_group_name = "mystorageaccount-rg"
```
