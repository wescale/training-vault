
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