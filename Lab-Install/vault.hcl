# all configuration options: https://developer.hashicorp.com/vault/docs/configuration
# lab sage

ui = true

storage "file" {
  path = "/opt/vault/data"
}

# HTTP listener
listener "tcp" {
  address     = "127.0.0.1:8200"
  tls_disable = 1
}


# HTTPS listener
# listener "tcp" {
#   address       = "0.0.0.0:8200"
#   tls_cert_file = "/opt/vault/tls/tls.crt"
#   tls_key_file  = "/opt/vault/tls/tls.key"
# }
