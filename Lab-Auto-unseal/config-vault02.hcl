ui = true

disable_mlock = true

# Don't change for container context
storage "file" {
  path = "/vault/file"
}

# HTTP listener
listener "tcp" {
  address     = "0.0.0.0:8100"
  tls_disable = 1
}

# Unseal config
seal "transit" {
  address = "http://server01:8200"
  disable_renewal = "false"
  key_name = "autounseal"
  mount_path = "transit/"
  tls_skip_verify = "true"
  # token = <unseal_token>
}