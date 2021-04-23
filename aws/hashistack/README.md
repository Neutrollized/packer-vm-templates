# README
With Graviton2 instances being GA in AWS and HashiCorp products being available for ARM64 architecture, I figured it's a good reason to build some images that utilize both!  This gives the best bang for the buck right now.

My `variables.pkrvars.hcl` file looks something like:
```
owner  = "1234567890"
region = "ca-central-1"

arch = "arm64"

consul_version = "1.9.5"
nomad_version  = "1.0.4"
vault_version  = "1.7.1"
```
