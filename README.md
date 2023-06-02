# packer-vm-templates
- Google Cloud (GCP) images built using GitHub Actions

### Convert (exiting) JSON to HCL2
```
packer hcl2_upgrade ./base.json
```

### Fix `debconf: unable to initialize frontend: Dialog` error
[link](https://discuss.hashicorp.com/t/how-to-fix-debconf-unable-to-initialize-frontend-dialog-error/39201/2)
