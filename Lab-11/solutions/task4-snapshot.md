# Task 4

## List peers and detect the leader

```bash
VAULT_TOKEN=$(grep 'Initial Root Token:' key-vault2.txt | awk '{print $NF}') VAULT_ADDR=http://127.0.0.1:8230 vault operator raft list-peers
```