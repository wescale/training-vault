# Lab - Application Integration

<walkthrough-tutorial-duration duration="30.0"></walkthrough-tutorial-duration>

## Description

* Task 1: Run Vault Agent
* Task 2: Use Envconsul to populate DB credentials
* Task 3: Use Consul template to populate DB credentials
* Task 4: Use Vault Agent Templates

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

## Task 1: Run Vault agent

Review App role install

```bash
cat setup-approle.sh
```

This script creates a new policy called, db_readonly . (This assumes that you have completed Lab 4.) It enables approle auth method, generates a role ID and stores it in
a file named, "roleID". Also, it generates a secret ID and stores it in the "secretID" file.

Execute the script

```bash
chmod +x setup-approle.sh
./setup-approle.sh
```

In a new shell, start agent:

```bash
cd ~/cloudshell_open/training-vault/Lab-10
vault agent -config=agent-config.hcl -log-level=debug
```

In a new shell, access agent:

```bash
export VAULT_AGENT_ADDR="http://127.0.0.1:8007"
```

Create a short-lived token and see how agent manages its lifecycle:

```bash
VAULT_TOKEN=$(cat approleToken) vault token create -ttl=30s -explicit-max-ttl=2m
```

Key                 |Value
---                 |-----
token               |hvs.CAESICyZQi6cbmhC44GII2plkU4HwzyEuJFyrgChKxVDz51XGh4KHGh2cy5yM3U0M21xVE9sSENoR3BpaGJGRDVtd3M
token_accessor      |T595xDRvmAtg5RvPW3Cr4U3G
token_duration      |30s
token_renewable     |true
token_policies      |["db_readonly" "default"]
identity_policies   |[]
policies            |["db_readonly" "default"]

Check Logs...

Test, your readonly settings

```bash
VAULT_TOKEN=$(cat approleToken) vault read database/creds/readonly
```

Key               |Value
---               |-----
lease_id          |database/creds/readonly/i11CtZulo3cuiKG8KYP6pxPu
lease_duration    |1h
lease_renewable   |true
password          |7GyqfqEDcc82t7Fu8ag-
username          |v-approle-readonly-FBkGQf0b9rPRW2TinTtI-1683899750

Check 

```bash
docker container exec -it postgres psql -U postgres

\du
```

## Task 2: Use Envconsul to populate DB credentials

Vault Agent can authenticate with Vault and acquire a client token. Now, use Envconsul to retrieve dynamic secrets from Vault and populate the username and password for your
application to connect with database.

View the app.sh file exists

```bash
cat app.sh
```

Run the Envconsul tool using the Vault token acquired by the Vault Agent Auto-Auth.

```bash
chmod +x app.sh
 VAULT_TOKEN=$(cat approleToken) envconsul -upcase -secret database/creds/readonly ./app.sh
```

Show the environment variables created by the Envconsul:

```bash
VAULT_TOKEN=$(cat approleToken) envconsul -upcase -secret database/creds/readonly env | grep DATABASE
```

DATABASE_CREDS_READONLY_USERNAME=v-approle-readonly-FBkGQf0b9rPRW2TinTtI-1683899750
DATABASE_CREDS_READONLY_PASSWORD=7GyqfqEDcc82t7Fu8ag-

## Task 3: Use Consul template to populate DB credentials

In the Secrets as a Service - Dynamic Secrets lab, you enabled and configured a database secret engine. Assuming that you have an application that needs database credentials,
use Consul Template to properly update the application file.

Check config template exists

```bash
cat config.yml.tpl
```

Generate a version of this template with the values populated with the consul-template command:

```bash
VAULT_TOKEN=$(cat approleToken) consul-template -template="config.yml.tpl:config.yml" -once
```

> The -once flag tells Consul Template not to run this process as a daemon, and just run it once.

Open the generated config.yml file to verify its content.

```bash
cat config.yml
```

## Task 4:  Use Vault Agent Templates

Consul Template is the client directly interacting with Vault; therefore, you had to pass a client token to Consul Template so that it can interact with Vault. This requires you to operate
two distinct tools (Vault Agent and Consul Template) to provide secrets to applications.
Vault Agent Templates allo

Examine the Vault Agent configuration file

```bash
cat agent-templates-config.hcl
```

Start the Vault Agent with agent-templates-config.hcl :

```bash
vault agent -config=agent-templates-config.hcl -log-level=debug
```

Verify that the secrets are rendered:

```bash
cat config-agent.yml
```

> Vault Agent is a client daemon that solves the secret-zero problem by authenticating with Vault and manage the client tokens on behalf of the client applications. The
Consul Template tool is widely adopted by the Vault users since it allowed applications to be "Vault-unaware".

## Clean Up

```bash
docker container rm -f $(docker container ls -aq)
```

```bash
sudo rm -rf vault01/
```