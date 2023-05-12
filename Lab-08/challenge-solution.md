# Lab 08 - Vault Policies

## Challenge

### olution

Create policy HCL file

```bash
cat <<EOT > challenge.hcl
# Requirement 1 and 3
path "kv/data/exercise/*" {
  capabilities = [ "create", "read", "update" ]
}
# Requirement 2 - explicit deny
path "kv/data/exercise/team-admin" {
  capabilities = [ "deny" ]
}
# Requirement 4
path "sys/policies/acl" {
  capabilities = [ "list" ]
}
# Requirement 5
path "sys/auth" {
  capabilities = [ "read" ]
}

EOT
```

Create policy

```bash
vault policy write exercise ./challenge.hcl
```

Generate a new token

```bash
vault token create -policy=exercise
```

Login with the new token

```bash
vault login <token>
```

Test requirement 1

```bash
vault kv put kv/exercise/test date="today"
vault kv get kv/exercise/test
vault token capabilities kv/data/exercise/test
```

Test requirement 2

```bash
vault kv put kv/exercise/team-admin status="active"
vault token capabilities kv/data/exercise/team-admin
```

Test requirement 3

```bash
vault kv delete kv/exercise/test
```

Test requirement 4

```bash
vault policy list
```

Test requirement 5

```bash
vault auth list
```

Finally, log back in with root token

```bash
vault login $(grep 'Initial Root Token:' key.txt | awk '{print $NF}')
```
