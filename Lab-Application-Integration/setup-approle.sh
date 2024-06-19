#!/usr/bin/env bash

# Create db_readonly policy
vault policy write db_readonly - <<POL
path "database/creds/readonly" {
  capabilities = [ "read" ]
}
path "/sys/leases/renew" {
  capabilities = [ "update" ]
}
path "auth/token/create" {
  capabilities = ["update"]
}
POL

# Enable database secrets engine
vault secrets enable database
vault write database/config/postgresql plugin_name="postgresql-database-plugin" allowed_roles="*" connection_url="postgresql://{{username}}:{{password}}@postgres/postgres" username=postgres password=password
vault write database/roles/readonly db_name=postgresql creation_statements=@readonly.sql default_ttl=1h max_ttl=24h

# Setup approle
vault auth enable approle
vault write auth/approle/role/apps policies="db_readonly"
echo $(vault read -format=json auth/approle/role/apps/role-id | jq  -r '.data.role_id') > roleID
echo $(vault write -f -format=json auth/approle/role/apps/secret-id | jq -r '.data.secret_id') > secretID