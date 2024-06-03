# Task 2 

## Vault 2 Init & Test

Test: open http://localhost:8220

Init

```bash
VAULT_ADDR=http://127.0.0.1:8220 vault operator init -recovery-shares 1 -recovery-threshold 1 > key-vault2.txt

VAULT_TOKEN=$(grep 'Initial Root Token:' key-vault2.txt | awk '{print $NF}') VAULT_ADDR=http://127.0.0.1:8220 vault token lookup
```

[Back](tutorial.md)