backend "file" {
  path = "vault"
}

listener "tcp" {
  tls_disable = 1
}

disable_mlock = true