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

### Docker Config with ECR Access
If you need to pull from a private ECR repo, you will need to fill in your account ID and region -- probably via userdata in your launch config if you're putting this in an autoscaling group (as you should):

```
{
	"auths": {
		"https://index.docker.io/v1/": {}
	},
	"credsStore": "ecr-login",
	"credHelpers": {
		"public.ecr.aws": "ecr-login",
		"{AWS_ACCOUNT_ID}.dkr.ecr.{AWS_REGION}.amazonaws.com": "ecr-login"
	}
}
```

#### NOTE
The `auths` section in there is so you can pull from a (public) Docker Hub repo.  If you don't have that, you can *only* pull from your private ECR.
