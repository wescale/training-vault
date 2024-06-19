# Task 5

## Restart and rejoin members

Restart the recovery nodes

```bash
docker container rm -f vault_3

docker container run --network pg  --cap-add IPC_LOCK -e VAULT_TOKEN=$(cat auto_unseal_token.txt) --name vault_3 -d -p 8230:8230 -p 8231:8231 -v $(pwd)/vault3-config.hcl:/vault/config/vault.hcl -v $(pwd)/vault_3/file/raft-vault:/vault/file/raft-vault hashicorp/vault:1.16.2 vault server -config=/vault/config/vault.hcl
```

Check logs

```bash
docker container logs vault_3

VAULT_TOKEN=$(grep 'Initial Root Token:' key-vault2.txt | awk '{print $NF}') VAULT_ADDR=http://127.0.0.1:8230 vault operator raft list-peers
```

Restart other nodes

```bash
docker container start vault_4

docker container start vault_2
```

Join the cluster

```bash
VAULT_ADDR=http://127.0.0.1:8220 vault operator raft join http://vault_3:8230
VAULT_ADDR=http://127.0.0.1:8240 vault operator raft join http://vault_3:8230
```

Check logs

```bash
docker container logs vault_2
docker container logs vault_4
```

Wait few minutes


```bash
VAULT_TOKEN=$(grep 'Initial Root Token:' key-vault2.txt | awk '{print $NF}') VAULT_ADDR=http://127.0.0.1:8230 vault operator raft list-peers
```