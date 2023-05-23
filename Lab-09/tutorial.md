# Lab 09 - Auto-unseal

<walkthrough-tutorial-duration duration="40.0"></walkthrough-tutorial-duration>

## Description

* Task 1: Configure Auto-unseal Key Provider
* Task 2: Configure Auto-unseal
* Task 3: Audit the incoming request
* Task 4: Rekeying & Rotation


## Init Lab - Vault Central Server

```bash
chmod +x vault.sh
./vault.sh
```

Test your setup

```bash
export VAULT_ADDR='http://127.0.0.1:8200' 
vault secrets list -detailed
```

## Task 1: Configure Auto-unseal Key Provider (Vault Central Server)

Enable the transit secrets engine and create a key.

Enable the transit secrets engine.

```bash
vault secrets enable transit
```
Success! Enabled the transit secrets engine at: transit/

Create a key named autounseal :

```bash
vault write -f transit/keys/autounseal
```

Success! Data written to: transit/keys/autounseal

Edit an autounseal policy

```bash
tee autounseal.hcl <<EOF
path "transit/encrypt/autounseal" {
   capabilities = [ "update" ]
}

path "transit/decrypt/autounseal" {
   capabilities = [ "update" ]
}
EOF
```

Create autounseal policy.

```bash
vault policy write autounseal autounseal.hcl
```

Create a new token with autounseal policy.

```bash
vault token create -policy="autounseal"
```

Key                 |Value
---                 |-----
token               |hvs.CAESIABIva_eNAI9XTcQcNYOOG4K3zb36OoKB1pRe20g2dZ5Gh4KHGh2cy42QnNkSnlJeVJVTGROaVhieFlTQUtEeEk
token_accessor      |KiozfZNmKkDsoD1HpwNqwsUh
token_duration      |768h
token_renewable     |true
token_policies      |["autounseal" "default"]
identity_policies   |[]
policies            |["autounseal" "default"]

Export your <unseal_token>

```bash
export VAULT_UNSEAL_TOKEN=<unseal_token>
```

## Task 2: Configure Auto-unseal (Vault Client)

Create a config file for Vault client

```bash
cat <<EOF > config-vault02.hcl

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

EOF
```

Start Vault Client (Docker container) and attach to Vault Central's docker network

```bash
docker container run --network pg -e VAULT_TOKEN=${VAULT_UNSEAL_TOKEN}  --cap-add IPC_LOCK --name server02 -d -p 8100:8100 -v $(pwd)/config-vault02.hcl:/vault/config/vault.hcl -v $(pwd)/vault02/file:/vault/file hashicorp/vault:1.12.4 vault server -config=/vault/config/vault.hcl

docker network connect pg server02
```

Open a new tab then

```bash
export VAULT_ADDR=http://127.0.0.1:8100
vault status
```

```bash
cd cloudshell_open/training-vault/Lab-09
vault operator init -recovery-shares=1 -recovery-threshold=1 > key-server02.txt

vault status
```

Login your container

```bash
export VAULT_TOKEN=$(grep 'Initial Root Token:' key-server02.txt | awk '{print $NF}')

vault secrets list -detailed
```

Enable audit

```bash
sudo mkdir -p vault02/file/audit
sudo chown -R 100:1000 vault02/file/audit

vault audit enable file file_path=/vault/file/audit/audit.log
```

Which **step** is missing ?

Restart your Vault Client container

```bash
docker container restart server02
docker container logs server02
```

## Task 3: Audit the incoming request

Audit the log on Vault central server

```bash
sudo tail vault01/file/audit/audit.log | jq
```


## Task 4: Rekeying & Rotation

When auto-unseal was enabled, your master key is protected by the cloud provider's key and NOT by the Shamir's keys. If the recovery keys have nothing to do with your master key, how do you rotate the encryption
key that is protecting your master key?
The answer is to rotate your cloud provider's key

> option for auto-unseal: `-target="recovery"`

```bash
vault operator rekey -init -key-shares=3 -key-threshold=2 \
-target="recovery" -format=json | jq -r ".nonce" > nonce.txt
```

Rekey your Vault

```bash
vault operator rekey -target=recovery -nonce=$(cat nonce.txt) $(grep 'Key 1:' key-server02.txt | awk '{print $NF}')
```

Key 1: AA83JXOVS/WH2ZAKXIOG2st9bKPxfj2qV4Krr1lbb8kn
Key 2: XWv+XePNgynW9Je9hNuYFlig2WID7ZhicKieAQQwxgNd
Key 3: bo7GKmGeUmNluT6yR4jDTvoDH1MkT0yz/UzI/Dd1khvj

Operation nonce: d4ed9abc-50e6-18a3-0549-a221bd87001f

Vault rekeyed with 3 key shares and a key threshold of 2. Please securely
distribute the key shares printed above. When Vault is re-sealed, restarted,
or stopped, you must supply at least 2 of these keys to unseal it before it
can start servicing requests.

With autounseal, you have to rotate key on transit 

```bash
vault write -f transit/keys/autounseal/rotate
```

To view key versions:

```bash
vault read transit/keys/autounseal
```

You can rotate your key

```bash
vault operator rotate
```

Restart your Vault Client to ensure everything is ok

```bash
docker container restart server02

docker container logs server02
```

## Clean Up

```bash
docker container rm -f $(docker container ls -aq)

sudo rm -rf vault01/
sudo rm -rf vault02/
```