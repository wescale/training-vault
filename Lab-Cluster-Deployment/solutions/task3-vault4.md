# Task 3

## Vault 4 Start & Init & Test

Start

```bash
sudo mkdir -p $(pwd)/vault_4/file/raft-vault
sudo chown 100:1000 $(pwd)/vault_4/file/raft-vault
docker container run --network pg  --cap-add IPC_LOCK -e VAULT_TOKEN=$(cat auto_unseal_token.txt) --name vault_4 -d -p 8240:8240 -p 8241:8241 -v $(pwd)/vault4-config.hcl:/vault/config/vault.hcl -v $(pwd)/vault_4/file/raft-vault:/vault/file/raft-vault hashicorp/vault:1.16.2 vault server -config=/vault/config/vault.hcl
```

```bash
docker container logs vault_4
```

Test: open http://localhost:8240

Join:

```bash
VAULT_ADDR=http://127.0.0.1:8240 vault operator raft join http://vault_2:8220

VAULT_TOKEN=$(grep 'Initial Root Token:' key-vault2.txt | awk '{print $NF}') VAULT_ADDR=http://127.0.0.1:8220 vault operator raft list-peers
```


[Back](tutorial.md)