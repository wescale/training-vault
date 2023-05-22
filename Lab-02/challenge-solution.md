# Lab 02 - Static Secret

## Challenge: Protect secrets from unintentional overwrite

### Option 1

Enable check-and-set at the secret/data/certificates level:

```bash
vault kv metadata put -cas-required secret/certificates
```

> This ensures that every write operation must pass the -cas flag.

```bash
vault kv put secret/certificates root="certificate.pem"
```

> The output should look similar to:
> 
> Error writing data to secret/data/certificates: Error making API request.
> 
> URL: PUT http://127.0.0.1:8200/v1/secret/data/certificates
> 
> Code: 400. Errors:
> 
> * check-and-set parameter required for this call
> In absence of the -cas flag, the write operation fails.

```bash
vault kv put -cas=0 secret/certificates root="certificate.pem"
```

The output should look similar to:

Key |Value
--- |-----
created_time |2018-06-11T21:59:06.055765168Z
deletion_time |n/a
destroyed |false
version |1

If you re-run the same command:

```bash
vault kv put -cas=0 secret/certificates root="certificate.pem"
```

Error writing data to secret/data/certificates: Error making API request.
URL: PUT http://127.0.0.1:8200/v1/secret/data/certificates
Code: 400. Errors:
* check-and-set parameter did not match the current version
Since -cas=0 allows the write operation only if there is no secret already exists at secret/certificates .

### Option 2

Require all team members to use the -cas flag with every write operation:


```bash
vault kv put -cas=1 secret/certificates root="certificate.pem"
```