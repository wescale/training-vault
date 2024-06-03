ui = true
disable_mlock = true
# Don't change for container context
storage "raft" {
  path    = "/vault/file/raft-vault/"
  node_id = "vault_4"
  # retry_join {
  #    leader_api_addr = "http://vault_2:8220"
  # }
  # retry_join {
  #    leader_api_addr = "http://vault_3:8230"
  # }
}

# HTTP listener
listener "tcp" {
  address     = "0.0.0.0:8240"
  cluster_address     = "0.0.0.0:8241"
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
api_addr = "http://0.0.0.0:8240"
cluster_addr = "http://vault_4:8241"