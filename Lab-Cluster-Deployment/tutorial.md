# Lab - Cluster Deployment

<walkthrough-tutorial-duration duration="45.0"></walkthrough-tutorial-duration>

## Description

* Task 1: Setup Auto-Unseal server
* Task 2: Create HA Cluster - with Integrated storage
* Task 3: Join Node Members
* Task 4: Snapshot management
* Task 5: Recovery mode 


## Init Lab

```bash
chmod +x vault-connect.sh
./vault-connect.sh
```

Test your setup

```bash
export VAULT_ADDR='http://127.0.0.1:8200' 
vault secrets list -detailed
```


What we will do :

* **vault_1** (http://127.0.0.1:8200) is initialized and unsealed. The root token creates a transit key that enables the other Vaults auto-unseal. This Vault does not join the cluster.

* **vault_2** (http://127.0.0.2:8220) is initialized and unsealed. This Vault starts as the cluster leader. An example K/V-V2 secret is created.

* **vault_3** (http://127.0.0.3:8230) is only started. You will join it to the cluster.

* **vault_4** (http://127.0.0.4:8240) is only started. You will join it to the cluster.

## Task 1: Setup Auto-Unseal server

Initialize vault_1 with transit key

```bash
chmod +x auto-unseal.sh
./auto-unseal.sh
```

Test your token

```bash
VAULT_TOKEN=$(cat auto_unseal_token.txt) vault token capabilities transit/encrypt/autounseal
```

update

## Task 2: Create HA Cluster - with Integrated storage

Start vault_2

chmod 0777 $(pwd)/vault_2/file/raft-vault

```bash
sudo mkdir -p $(pwd)/vault_2/file/raft-vault
sudo chown 100:1000 $(pwd)/vault_2/file/raft-vault
docker container run --network pg  --cap-add IPC_LOCK -e VAULT_TOKEN=$(cat auto_unseal_token.txt) --name vault_2 -d -p 8220:8220 -p 8221:8221 -v $(pwd)/vault2-config.hcl:/vault/config/vault.hcl -v $(pwd)/vault_2/file/raft-vault:/vault/file/raft-vault hashicorp/vault:1.12.4 vault server -config=/vault/config/vault.hcl
```

Check logs

```bash
docker container logs vault_2
```

Init & Test you server

[Solution](solutions/task2-vault2.md)

## Task 3: Join Node Members

Start vault_3

Port Addr : 8230
Cluster Port Addr: 8231

[Solution](solutions/task3-vault3.md)

Join:

```bash
VAULT_ADDR=http://127.0.0.1:8230 vault operator raft join http://vault_2:8220

VAULT_TOKEN=$(grep 'Initial Root Token:' key-vault2.txt | awk '{print $NF}') VAULT_ADDR=http://127.0.0.1:8220 vault operator raft list-peers
```

Start vault_4 and Join

[Solution](solutions/task3-vault4.md)

Test Raft

```bash
VAULT_TOKEN=$(grep 'Initial Root Token:' key-vault2.txt | awk '{print $NF}') VAULT_ADDR=http://127.0.0.1:8220 vault secrets enable -path=kv/ kv-v2

VAULT_TOKEN=$(grep 'Initial Root Token:' key-vault2.txt | awk '{print $NF}') VAULT_ADDR=http://127.0.0.1:8220 vault kv put kv/training_test password="password1234"
```

> then read the secret on member

```bash
VAULT_TOKEN=$(grep 'Initial Root Token:' key-vault2.txt | awk '{print $NF}') VAULT_ADDR=http://127.0.0.1:8230 vault kv get kv/training_test
```

## Task 4: Snapshot management

Take a snapshot of your cluster

```bash
VAULT_TOKEN=$(grep 'Initial Root Token:' key-vault2.txt | awk '{print $NF}') VAULT_ADDR=http://127.0.0.1:8220 vault operator raft snapshot save demo.snapshot
```

Restart vault_2 and try take snapshot

```bash
docker container restart vault_2

VAULT_TOKEN=$(grep 'Initial Root Token:' key-vault2.txt | awk '{print $NF}') VAULT_ADDR=http://127.0.0.1:8220 vault operator raft snapshot save demo.snapshot
```

Find the leader and take the snapshot

[Solution](solutions/task4-snapshot.md)

> Restore snapshot

Simulate data loss

```bash
VAULT_TOKEN=$(grep 'Initial Root Token:' key-vault2.txt | awk '{print $NF}') VAULT_ADDR=http://127.0.0.1:8230 vault kv get kv/training_test

VAULT_TOKEN=$(grep 'Initial Root Token:' key-vault2.txt | awk '{print $NF}') VAULT_ADDR=http://127.0.0.1:8230 vault kv metadata delete kv/training_test


VAULT_TOKEN=$(grep 'Initial Root Token:' key-vault2.txt | awk '{print $NF}') VAULT_ADDR=http://127.0.0.1:8230 vault kv get kv/training_test
```

Then restore the snapshot

```bash
VAULT_TOKEN=$(grep 'Initial Root Token:' key-vault2.txt | awk '{print $NF}') VAULT_ADDR=http://127.0.0.1:8230 vault operator raft snapshot restore demo.snapshot
```

Try to find the secret lost

```bash
VAULT_TOKEN=$(grep 'Initial Root Token:' key-vault2.txt | awk '{print $NF}') VAULT_ADDR=http://127.0.0.1:8230 vault kv get kv/training_test
```

## Task 5: Recovery mode 

Simulate an outage (stop all instances)

```bash
docker container stop vault_2
docker container stop vault_4
```

Then stop the leader

```bash
docker container stop vault_3
```

Delete container 3 to pass it in recovery mode

```bash
docker container rm vault_3

docker container run --network pg  --cap-add IPC_LOCK -e VAULT_TOKEN=$(cat auto_unseal_token.txt) --name vault_3 -d -p 8230:8230 -p 8231:8231 -v $(pwd)/vault3-config.hcl:/vault/config/vault.hcl -v $(pwd)/vault_3/file/raft-vault:/vault/file/raft-vault hashicorp/vault:1.12.4 vault server -recovery -config=/vault/config/vault.hcl
```

Check the logs & Status

```bash
docker container logs vault_3

VAULT_ADDR=http://127.0.0.1:8230 vault status
```

Generate recovery token

```bash
VAULT_ADDR=http://127.0.0.1:8230 vault operator generate-root -generate-otp -recovery-token
```

Start generation recovery token from OTP

```bash
VAULT_ADDR=http://127.0.0.1:8230 vault operator generate-root -init -otp=<your otp token> -recovery-token
```

Nonce        |8d269b33-295d-679f-e0f4-9c954df65303
Started      |true
Progress     |0/1
Complete     |false
OTP|Length   |28


Then generate encoded token

```bash
VAULT_ADDR=http://127.0.0.1:8230 vault operator generate-root -recovery-token
```

Found Recovery key in early step in file `key-vault2.txt`

Operation nonce: 8d269b33-295d-679f-e0f4-9c954df65303
Unseal Key (will be hidden): 
Nonce           |8d269b33-295d-679f-e0f4-9c954df65303
Started         |true
Progress        |1/1
Complete        |true
Encoded|Token   |JwUkehkVFRQMNzktHycHXjgDDEETYgxrGSV3AA

Complete creation

```bash
VAULT_ADDR=http://127.0.0.1:8230 vault operator generate-root \
  -decode=<your encoded token> \
  -otp=<your otp token> \
  -recovery-token
```

Here we are !!

> You must receive a recovery token like: hvr.orQP5TzXzPk8ZuJrbUTRkc5B

Then you can perform RAW actions

```bash
VAULT_ADDR=http://127.0.0.1:8230 VAULT_TOKEN=hvr.orQP5TzXzPk8ZuJrbUTRkc5B vault list sys/raw/sys
```


> The cluster is resize to 1 member so we can restart node and join the cluster

[Solution](solutions/task5-recovery.md)

## Clean Up (only at the end of the training)

```bash
docker container rm -f $(docker container ls -aq)
```

```bash
sudo rm -rf vault01/
sudo rm -rf vault_2/
sudo rm -rf vault_3/
sudo rm -rf vault_4/
```