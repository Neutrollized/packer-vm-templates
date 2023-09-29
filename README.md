# packer-vm-templates

### Google Cloud (GCP) images built using GitHub Actions
You will need to [create secrets for Github repo](https://docs.github.com/en/actions/security-guides/encrypted-secrets?tool=webui#creating-encrypted-secrets-for-a-repository) for:
- `GCP_PROJECT_ID`, which contains the value of your GCP project ID
- `GCP_CREDENTIALS_JSON`, which contains the credential JSON file contents for the GCP service account used to create the image

### Convert (exiting) JSON to HCL2
```
packer hcl2_upgrade ./base.json
```

### Fix `debconf: unable to initialize frontend: Dialog` error
[link](https://discuss.hashicorp.com/t/how-to-fix-debconf-unable-to-initialize-frontend-dialog-error/39201/2)
