# README
With Graviton2 instances being GA in AWS and HashiCorp products being available for ARM64 architecture, I figured it's a good reason to build some images that utilize both!  This gives the best bang for the buck right now.

My `variables.pkrvars.hcl` file looks something like:
```
owner  = "1234567890"
region = "ca-central-1"

arch = "arm64"

consul_version = "1.9.6"
nomad_version  = "1.1.1"
vault_version  = "1.7.2"
```

## Nomad Client
Nomad clients need to be AMD64 arch becuase it needs to run Docker which as to run the container images and unless your images are build on ARM64 arch, you're gonna have issues. 
