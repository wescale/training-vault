# Lab - Dynamic Secret Engine

<walkthrough-tutorial-duration duration="35.0"></walkthrough-tutorial-duration>

## Description

* Task 1: Enable and configure a database secret engine
* Task 2: Create and manage a static role
* Task 3: Generate dynamic readonly credentials
* Task 4: Revoke leases

* Challenge: Setup database secret engine via API

## Init Lab


On first launch only

```bash
chmod +x ../install-cli.sh
../install-cli.sh
```

```bash
chmod +x ../vault.sh
../vault.sh
```

Reconnect to the lab

```bash
chmod +x ../vault-connect.sh
../vault-connect.sh
```


Restart from long sleep to the lab (not container or install)

```bash
chmod +x ../install-cli.sh
../install-cli.sh
```

```bash
chmod +x ../vault-restart.sh
../vault-restart.sh
```

```bash
export VAULT_ADDR='http://127.0.0.1:8200' 

vault secrets list -detailed
```

## Task 1: Enable and configure a database secret engine

Activate Dynamic secret for database

```bash
vault secrets enable database
vault path-help database/
```

Configure 

```txt
vault write database/config/postgresql \
plugin_name="postgresql-database-plugin" \
allowed_roles="*" \
connection_url="postgresql://{{username}}:{{password}}@postgres/postgres" \
username=postgres \
password=password
```

Configure postgres

```bash
docker container exec -it postgres psql -U postgres
```

```bash
CREATE ROLE "vault-edu" WITH LOGIN PASSWORD 'mypassword';
```

```bash
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "vault-edu";
```

```bash
\du
\q
```

check rotation.sql
```bash
cat rotation.sql 
```

## Task 2: Enable and configure a database secret engine

Create static in Vault

```bash
vault write database/static-roles/education \
db_name=postgresql \
rotation_statements=@rotation.sql \
username="vault-edu" \
rotation_period=86400
```

Test the role

```bash
vault read database/static-roles/education
```

Key                   |Value
---                   |-----
credential_type       |password
db_name               |postgresql
last_vault_rotation   |2023-03-23T15:45:38.066623572Z
rotation_period       |24h
rotation_statements   |[ALTER USER "{{name}}" WITH PASSWORD '{{password}}';]
username              |vault-edu

Retreive password

```bash
vault read database/static-creds/education
```

Key                   |Value
---                   |-----
last_vault_rotation   |2023-03-23T15:45:38.066623572Z
password              |WOSapa-C0lZDR3Evq4uf
rotation_period       |24h
ttl                   |23h58m32s
username              |vault-edu

Connect to DB

```bash
docker container exec -it postgres psql -h postgres -d postgres -U vault-edu

```

```bash
\c 
\q
```

> You are now connected to database "postgres" as user "vault-edu".

Force renew password

```bash
vault write -f database/rotate-role/education
```

## Task 3: Generate dynamic readonly credentials

Vault requires that you define the SQL to create credentials associated with this dynamic, readonly role. The SQL required to generate this role can be found in the file
readonly.sql

check readonly.sql
```bash
cat readonly.sql 
```

Configure the role

```bash
vault write database/roles/readonly db_name=postgresql \
creation_statements=@readonly.sql \
default_ttl=1h max_ttl=24h
```

> This command creates a role named, readonly which has a default TTL of 1 hour, and max TTL is 24 hours. The credentials for the readonly role expires after 1
hour, but can be renewed multiple times within 24 hours of its creation.

```bash
vault read database/creds/readonly
```

generate new creds

```bash
vault read database/creds/readonly
```

Verify

```bash
docker container exec -it postgres psql -U postgres
```

Verify and Disconnect

```bash
\du
\q
```

## Task 4: Revoke leases


> Lease id can be found when you read creds !
choose your lease id path

```txt
export my_pg_lease="database/creds/readonly/<adapt>"
```

Renew lease

```bash
vault lease renew $my_pg_lease
```

```hcl
# Get credentials from the database backend
path "database/creds/readonly" {
capabilities = [ "read" ]
}
# Renew the lease
path "/sys/leases/renew" {
capabilities = [ "update" ]
}
```

Increment lease

```bash
vault lease renew -increment=2h $my_pg_lease
```

Revoke lease

```bash
vault lease revoke $my_pg_lease
```



Revoke with prefix

Generate some creds

```txt
for i in {1..100}
do
    vault read database/creds/readonly 
done

docker container exec -it postgres psql -U postgres
```

exit container
```bash
\du
\q
```

revoke with prefix

```bash
vault lease revoke -prefix database/creds/readonly

```

Control postgres


```bash
docker container exec -it postgres psql -U postgres
```

check and exit
```
\du
\q
```

## Challenge: Setup database secret engine via API



## Clean Up (only at the end of the training)

```bash
chmod +x ../cleanup-install.sh
../cleanup-install.sh
```
