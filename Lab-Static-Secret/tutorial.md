# Lab - Static Secret

<walkthrough-tutorial-duration duration="35.0"></walkthrough-tutorial-duration>

## Description

* Task 1: Write key/value secrets using CLI
* Task 2: List secret keys using CLI
* Task 3: Delete secrets using CLI
* Task 4: Manage the key/value secret engine using API
* Task 5: Explore web UI exclusive features

* Challenge: Protect secrets from unintentional overwrite

## Download & Install vault cli (1st time only)

```bash
wget https://releases.hashicorp.com/vault/1.16.2/vault_1.16.2_linux_amd64.zip
unzip vault_1.16.2_linux_amd64.zip
chmod +x vault

sudo mv vault /usr/bin/
vault version

rm -f vault_1.16.2_linux_amd64.zip

```

switch to vault unsecure

```bash
export VAULT_ADDR='http://127.0.0.1:8200' 
```

## Start Vault Server (1st time only)

```bash
chmod +x vault.sh
./vault.sh
```

List secrets

```bash
vault secrets list -detailed
```

## Task 1 Write key/value secrets using CLI

```bash
vault secrets enable -path=secret kv-v2
```

```bash
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

```txt
echo '
{
"organization": "WeScale",
"region": "FR-West3"
}
' | sudo tee vault01/file/data.json

```

```bash
vault kv put secret/company @vault01/file/data.json
```

```bash
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

```bash
vault kv put -output-curl-string secret/apikey/google apikey="my-api-key"

```

> curl -X PUT -H "X-Vault-Token: $(vault print token)" -d '{"data":{"apikey":"my-api-key"},"options":{}}' http://127.0.0.1:8200/v1/secret/data/apikey/google | jq


Generate a command to get secret path

```bash
vault kv get -output-curl-string secret/apikey/google
```

> curl -H "X-Vault-Token: $(vault print token)" http://127.0.0.1:8200/v1/secret/data/apikey/google | jq

With jq you can extract a portion of response

> curl -H "X-Vault-Token: $(vault print token)" http://127.0.0.1:8200/v1/secret/data/apikey/google | jq ".data.data.apikey"


Generate delete command

```bash
vault kv delete -output-curl-string secret/apikey/google
```

> curl -X DELETE -H "X-Vault-Token: $(vault print token)" \
> http://127.0.0.1:8200/v1/secret/data/apikey/google

Visit UI to show your secret

## Task5 Explore web UI exclusive features


## Challenge: Protect secrets from unintentional overwrite

* Option 1: Enable check-and-set at the secret/data/certificates level
* Option 2: Require all team members to use the -cas flag with every write operation


## Clean Up (only at the end of the training)


```bash
docker container rm -f $(docker container ls -aq)
```

```bash
sudo rm -rf vault01/
```