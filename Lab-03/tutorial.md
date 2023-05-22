# Lab 03 - Dynamic Secret Engine

<walkthrough-tutorial-duration duration="35.0"></walkthrough-tutorial-duration>

## Description

* Task 1: Enable and configure a database secret engine
* Task 2: Create and manage a static role
* Task 3: Generate dynamic readonly credentials
* Task 4: Revoke leases

* Challenge: Setup database secret engine via API

## Init Lab

```bash
chmod +x vault.sh
./vault.sh
export VAULT_ADDR='http://127.0.0.1:8200' 
# -e POSTGRES_PASSWORD=mysecretpassword
```

## Task 1: Enable and configure a database secret engine

Activate Dynamic secret for database

```bash
vault secrets enable database
vault path-help database/

Configure 

```bash
vault write database/config/postgresql \
plugin_name="postgresql-database-plugin" \
allowed_roles="*" \
connection_url="postgresql://postgres:password@postgres/postgres"
```

Configure postgres

```bash
docker container exec -it postgres psql -U postgres

CREATE ROLE "vault-edu" WITH LOGIN PASSWORD 'mypassword';
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "vault-edu";

\du
\q

cat << EOF > rotation.sql 
ALTER USER "{{name}}" WITH PASSWORD '{{password}}';
EOF
```

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

\c 
\q
```

> You are now connected to database "postgres" as user "vault-edu".

Force renew password

```bash
vault write -f database/rotate-role/education

## Task 3: Generate dynamic readonly credentials

Vault requires that you define the SQL to create credentials associated with this dynamic, readonly role. The SQL required to generate this role can be found in the file
readonly.sql
```

```bash
cat <<EOF > readonly.sql
CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
REVOKE ALL ON SCHEMA public FROM public, "{{name}}";
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "{{name}}";
EOF
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

\du
```

Renew lease

```bash
vault lease renew database/creds/readonly/cE4Nd4BO6akHrj9YOkEN5f6h
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
vault lease renew -increment=2h database/creds/readonly/cE4Nd4BO6akHrj9YOkEN5f6h
```

Revoke lease

```bash
vault lease revoke database/creds/readonly/cE4Nd4BO6akHrj9YOkEN5f6h
```



revoke with prefix

Generate some creds

```bash
for i in {1..100}
do
 vault read database/creds/readonly
done
docker container exec -it postgres psql -U postgres

\du
\q
```

revoke with prefix

```bash
vault lease revoke -prefix database/creds/readonly

Control postgres


```bash
docker container exec -it postgres psql -U postgres

\du
\q
```

## Challenge: Setup database secret engine via API



## Clean Up

```bash
docker container rm -f $(docker container ls -aq)

sudo rm -rf vault01/
```