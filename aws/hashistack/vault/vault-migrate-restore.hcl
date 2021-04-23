storage_source "file" {
  path = "/tmp/vault-backup"
}

storage_destination "consul" {
  address = "127.0.0.1:8500"
  path    = "vault"
}
