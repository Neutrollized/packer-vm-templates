storage_source "consul" {
  address = "127.0.0.1:8500"
  path    = "vault"
}

storage_destination "file" {
  path = "/tmp/vault-backup"
}
