# /etc/nomad.d/client.hcl
# this requires consul to be running as it finds the Nomad servers via service discovery

datacenter = "{CLOUD}-{ENV}"
region = "{REGION}"

# Increase log verbosity
log_level = "INFO"

# Setup data dir
data_dir = "/opt/nomad"

# https://www.nomadproject.io/guides/security/acl.html#enable-acls-on-nomad-clients
acl {
  enabled = true
}

# Enable the client
client {
  enabled = true

  # using Consul service discovery to find Nomad server
  servers = ["nomad.service.consul:4647"]
}

# https://www.nomadproject.io/docs/configuration/vault.html
#vault {
#  enabled = true
#
#  address = "{VAULT_ADDR}"
#}

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/private-auth-container-instances.html
# https://www.nomadproject.io/docs/drivers/docker.html#client-requirements
# this will set private registry auths to use the dockercfg file
# instead of having to pass in 'username' and 'password' in the auth stanza of your job
plugin "docker" {
  config {
    auth {
      config = "/root/.docker/ecr-config.json"
    }
  }
}
