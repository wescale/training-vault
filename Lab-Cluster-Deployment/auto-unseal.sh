#!/usr/bin/env bash

export ROOT_DIR_PATH=$(dirname $(realpath "$0"))


export VAULT_ADDR='http://127.0.0.1:8200'

vault login $(grep 'Initial Root Token:' $ROOT_DIR_PATH/vault-key.txt | awk '{print $NF}')


vault secrets enable transit
vault write -f transit/keys/autounseal

tee autounseal.hcl <<EOF
path "transit/encrypt/autounseal" {
   capabilities = [ "update" ]
}
path "transit/decrypt/autounseal" {
   capabilities = [ "update" ]
}
EOF

vault policy write autounseal autounseal.hcl

vault token create -format=json -policy="autounseal" | jq -r '.auth.client_token' > auto_unseal_token.txt