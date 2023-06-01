# README

`PKR_VAR_access_token='xxxxxxxxxxxxx' packer build -var 'project_id=myproject-123' -var-file=variables.pkrvars.hcl base_docker.pkr.hcl`

**NOTE**: obtain access_token with `gcloud auth print-access-token`


## TODO
- add Vault Agent config to Nomad clients
