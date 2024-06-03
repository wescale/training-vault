# Task 3

## Vault 3 Start & Init & Test

Start

```bash
sudo mkdir -p $(pwd)/vault_3/file/raft-vault
sudo chown 100:1000 $(pwd)/vault_3/file/raft-vault
docker container run --network pg  --cap-add IPC_LOCK -e VAULT_TOKEN=$(cat auto_unseal_token.txt) --name vault_3 -d -p 8230:8230 -p 8231:8231 -v $(pwd)/vault3-config.hcl:/vault/config/vault.hcl -v $(pwd)/vault_3/file/raft-vault:/vault/file/raft-vault hashicorp/vault:1.12.4 vault server -config=/vault/config/vault.hcl
```

Check logs

```bash
docker container logs vault_3
```

Test: open http://localhost:8230

Init > not needed

[Back](tutorial.md)