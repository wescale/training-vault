# Lab 02 - Static Secret

<walkthrough-tutorial-duration duration="25.0"></walkthrough-tutorial-duration>

## Description

Task 1: Write key/value secrets using CLI
Task 2: List secret keys using CLI
Task 3: Delete secrets using CLI
Task 4: Manage the key/value secret engine using API
Task 5: Explore web UI exclusive features

Challenge: Protect secrets from unintentional overwrite

## Download & Install vault cli

wget https://releases.hashicorp.com/vault/1.12.4/vault_1.12.4_linux_amd64.zip
unzip vault_1.12.4_linux_amd64.zip
chmod +x vault

sudo mv vault /usr/bin/

export VAULT_ADDR='http://127.0.0.1:8200' 

## Start Vault Server

```bash
docker container run --cap-add IPC_LOCK --name server01 -d -p 8200:8200 -v $(pwd)/../exercise-1/Vault/vault.hcl:/vault/config/vault.hcl -v $(pwd)/vault01/file:/vault/file hashicorp/vault:1.12.4 vault server -config=/vault/config/vault.hcl
```

open http://127.0.0.1:8200

## Init Vault

```bash

vault operator init -key-shares=1 -key-threshold=1 key.txt
```

Unseal Vault

```bash
vault operator unseal $(grep 'Key 1:' key.txt | awk '{print $NF}')
```

Login to Vault

```bash
vault login $(grep 'Initial Root Token:' key.txt | awk '{print $NF}')
```

Activate audit

```bash
mkdir vault01/file/audit
sudo chown -R 100:1000 vault01/file/audit

vault audit enable file file_path=/vault/file/audit/audit.log
```

List secrets

```bash
vault secrets list -detailed
```

## Task 1 Write key/value secrets using CLI

```bash
vault secrets enable -path=secret kv-v2

vault kv put secret/training username="student01" password="pAssw0rd"
```

### Explore K/V Secrets Engine

Get Secret

```bash
vault kv get secret/training

vault kv get -field=username secret/training
```

new version 

```bash
vault kv put secret/training password="another-password"
```

> username was removed

Partial Update

```bash
vault kv patch secret/training course="Vault by WeScale 101"
```

Create secret with file

```bash
cat << EOF > vault01/file/data.json
{
"organization": "WeScale",
"region": "FR-West3"
}
EOF

vault kv put secret/company @vault01/file/data.json

vault kv get secret/company
```

## Task2 List secret keys using CLI

Get Help

```bash
vault kv list -h
```

List secret 

```bash
vault kv list secret
```

## Task3 Delete secrets using CLI

Get Help

```bash
vault kv delete -h
```

Delete secret company

```bash
vault kv delete secret/company
```

Does secret exist anymore ?

```bash
vault kv get secret/company
```

> to permanently remove secret: `vault kv destroy` or `vault kv metadata delete`

## Task4 Manage the key/value secret engine using API

Vault help you to create curl command to access Vault through API

vault kv put -output-curl-string secret/apikey/google apikey="my-api-key"

curl -X PUT -H "X-Vault-Token: $(vault print token)" \
-d '{"data":{"apikey":"my-api-key"},"options":{}}' \
http://127.0.0.1:8200/v1/secret/data/apikey/google | jq


Generate a command to get secret path

vault kv get -output-curl-string secret/apikey/google
curl -H "X-Vault-Token: $(vault print token)" \
http://127.0.0.1:8200/v1/secret/data/apikey/google | jq

With jq you can extract a portion of response

curl -H "X-Vault-Token: $(vault print token)" \
http://127.0.0.1:8200/v1/secret/data/apikey/google | jq ".data.data.apikey"


Generate delete command

vault kv delete -output-curl-string secret/apikey/google
 curl -X DELETE -H "X-Vault-Token: $(vault print token)" \
http://127.0.0.1:8200/v1/secret/data/apikey/google

Visit UI to show your secret

## Task5 Explore web UI exclusive features



## Clean Up

```bash
docker container rm -f $(docker container ls -aq)

sudo rm -rf vault01/
```