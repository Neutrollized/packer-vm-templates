# https://www.vaultproject.io/docs/configuration/storage/raft
storage "raft" {
  path    = "/opt/vault/raft"
  node_id = "raft_node_{RAFT_NODE_NUMBER}"
}

# https://www.vaultproject.io/docs/configuration/service-registration/consul
# registering with the local Consul agent
service_registration "consul" {
  address      = "127.0.0.1:8500"
}

# change tls_disable to false once you've set up properly ALBs, etc.
listener "tcp" {
  address     = "{PRIVATE_IPV4}:8200"
  tls_disable = true
}

ui = true
api_addr = "http://{PRIVATE_IPV4}:8200"
cluster_addr = "https://{PRIVATE_IPV4}:8201"
