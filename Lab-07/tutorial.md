# Lab 07 - Vault Authentication and Tokens

<walkthrough-tutorial-duration duration="40.0"></walkthrough-tutorial-duration>

## Description

* Task 1: Create a Short-Lived Tokens
* Task 2: Token Renewal
* Task 3: Create Tokens with Use Limit
* Task 4: Create a Token Role and Periodic Token
* Task 5: Create an Orphan Token
* Task 6: Enable Username and Password Auth Method

* Challenge: Generate batch tokens

## Init Lab

```bash
chmod +x vault.sh
./vault.sh
```

Test your setup

```bash
export VAULT_ADDR='http://127.0.0.1:8200' 
vault secrets list -detailed
```

## Task 1: Create Short-Lived Tokens

> When you have a scenario where an app talks to Vault only to retrieve a secret (e.g. API key), and never again. If the interaction between Vault and its client takes only a few seconds,
there is no need to keep the token alive for longer than necessary. Let's create a token which is only valid for 30 seconds.


Review the help message on token creation:

```bash
vault token create -h
```

Create a token whose TTL is 30 seconds:

```bash
vault token create -ttl=30
```

Key                 |Value
---                 |-----
token               |hvs.QBYzJNiGFrAJXx1vtLO5Pcn0
token_accessor      |eetmzhXXmLhRUlkdp0VDM3Dd
token_duration      |30s
token_renewable     |true
token_policies      |["root"]
identity_policies   |[]
policies            |["root"]

Lookup token information

```bash
vault token lookup <your token>
```

Key                |Value
---                |-----
accessor           |XUKM9aDOiUXbsszvCGassL1x
creation_time      |1683880040
creation_ttl       |30s
display_name       |token
entity_id          |n/a
expire_time        |2023-05-12T08:27:50.069419847Z
explicit_max_ttl   |0s
id                 |hvs.NhBRzQajsDqfMd3GOQNLZtH8
issue_time         |2023-05-12T08:27:20.069428896Z
meta               |<nil>
num_uses           |0
orphan             |false
path               |auth/token/create
policies           |[root]
renewable          |true
ttl                |5s
type               |service

> /!\ Wait until end of TTL

Lookup token information

```bash
vault token lookup <your token>
```

Error looking up token: Error making API request.

URL: POST http://127.0.0.1:8200/v1/auth/token/lookup
Code: 403. Errors:

* bad token

## Task 2: Token Renewal

Review the help message on token creation:

```bash
vault token renew -h
```

Let's create another token with default policy and TTL of 120 seconds:

```bash
vault token create -ttl=120 -policy="default"
```

Key                  |Value
---|                  -----
token                |hvs.AESIBB-iu_lj9PKqHM_e7eQqto7aXaRM71xjI4qTM1q6CdyGh4KHGh2cy5DRVhDQmdsWW5tRGtnelQzZVBvY2lLa1c
token_accessor       |ppp5ujlFTkFV4vboe8KXFAwM
token_duration       |2m
token_renewable      |true
token_policies       |["default"]
identity_policies    |[]
policies             |["default"]

Lookup information about the <token_task_2> :

```bash
vault token lookup <token_task_2>
```

Renew the token and double its TTL:

```bash
vault token renew -increment=240 <token_task_2>
```

Key                 |Value
---                 |-----
token               |hvs.CAESIL-g1einIGoZqNfwO9Ayqlyr2MJ3wISzO9-p5xRN9fzhGh4KHGh2cy44YXpnNUpxb3l0QjY0Sk9OTFNNRWI5UWs
token_accessor      |ebGg6TCBNSvHffXlepe4xDZU
token_duration      |4m
token_renewable     |true
token_policies      |["default"]
identity_policies   |[]
policies            |["default"]


Look up the token details again to verify that is TTL has been updated.

```bash
vault token lookup <token_task_2>
```

Key                 |Value
---                 |-----
accessor            |ebGg6TCBNSvHffXlepe4xDZU
creation_time       |1683880835
creation_ttl        |2m
display_name        |token
entity_id           |n/a
expire_time         |2023-05-12T08:45:36.691565482Z
explicit_max_ttl    |0s
id                  |hvs.CAESIL-g1einIGoZqNfwO9Ayqlyr2MJ3wISzO9-p5xRN9fzhGh4KHGh2cy44YXpnNUpxb3l0QjY0Sk9OTFNNRWI5UWs
issue_time          |2023-05-12T08:40:35.366643705Z
last_renewal        |2023-05-12T08:41:36.691565592Z
last_renewal_time   |1683880896
meta                |<nil>
num_uses            |0
orphan              |false
path                |auth/token/create
policies            |[default]
renewable           |true
ttl                 |2m5s
type                |service


## Task 3: Create Tokens with Use Limit

Create a token with use limit of 2.

```bash
vault token create -use-limit=2
```

Key                 |Value
---                 |-----
token               |hvs.6JHYQ8TSHtRrnhYjAjaCPsnH
token_accessor      |hNJtrv77ZkH2rrUHsm4Xfrv0
token_duration      |∞
token_renewable     |false
token_policies      |["root"]
identity_policies   |[]
policies            |["root"]

Look up information about the token to consume 1 of the token's uses:

```bash
VAULT_TOKEN=<token_task_3> vault token lookup
```

Key                 |Value
---                 |-----
...                 |...
num_uses            |1

Write a key/value to path cubby/hole/test to consume another of the token's uses:

```bash
VAULT_TOKEN=<token_task_3> vault write cubbyhole/test name="test01"
```
Success! Data written to: cubbyhole/test

Try to read you secret

```bash
VAULT_TOKEN=<token_task_3> vault read cubbyhole/test
```

Error reading cubbyhole/test: Error making API request.

URL: GET http://127.0.0.1:8200/v1/cubbyhole/test
Code: 403. Errors:

* permission denied

vault token renew hvs.6JHYQ8TSHtRrnhYjAjaCPsnH

## Task 4: Create an Orphan Token

Create a token with TTL of 90 seconds.

```bash
vault token create -ttl=90
```

Key                 |Value
---                 |-----
token               |hvs.MDy72UiuRucXPZSSISLLMKcb
token_accessor      |B77d2NAiqto6XJopnHjMcAKf
token_duration      |1m30s
token_renewable     |true
token_policies      |["root"]
identity_policies   |[]
policies            |["root"]

Create a child token of the <token_task_4> with a longer TTL of 180 seconds:

```bash
VAULT_TOKEN=<token_task_4> vault token create -ttl=180
```

Key                 |Value
---                 |-----
token               |hvs.U0TDtN7dG7pV7sLUb3PICWWB
token_accessor      |Px5VVGywWE3vxdFexAW1rRkg
token_duration      |3m
token_renewable     |true
token_policies      |["root"]
identity_policies   |[]
policies            |["root"]

our hierachy:

root
  |__ hvs.MDy72UiuRucXPZSSISLLMKcb (TTL = 90 seconds)
    |__ hvs.U0TDtN7dG7pV7sLUb3PICWWB (TTL = 180 seconds)

After 90 seconds, the <token_task_4> expires! This automatically revokes its child token. If you try to look up the child token, you should receive bad token error since
the token was revoked when its parent expired.
Wait 90 seconds and then lookup details about the <child_token> :

```bash
vault token lookup <child_token>
```

Error looking up token: Error making API request.

URL: POST http://127.0.0.1:8200/v1/auth/token/lookup
Code: 403. Errors:

* bad token

> Now, if this behavior is undesirable, you can create an orphan token instead.

Create a new token with a TTL of 90 seconds

```bash
vault token create -ttl=90
```

Key                 |Value
---                 |-----
token               |hvs.pJewKgz1eKgzQicZ3tRIQlQh
token_accessor      |UOcWbE2s44XNIvFWmraUpPf5
token_duration      |1m30s
token_renewable     |true
token_policies      |["root"]
identity_policies   |[]
policies            |["root"]

Copy the value of token . The remaining commands in this step will refer to it as <token_parent> .

Next, create a child token with the -orphan flag.


```bash
VAULT_TOKEN=<token_parent> vault token create -ttl=180 -orphan
```

Key                 |Value
---                 |-----
token               |hvs.fWXNTRGWgOBuub3xGMBRnH5D
token_accessor      |cUvrGwjBNI1CNQakzWEZUAej
token_duration      |3m
token_renewable     |true
token_policies      |["root"]
identity_policies   |[]
policies            |["root"]

Revoke <token_parent>

```bash
vault token revoke <token_parent>
```

Success! Revoked token (if it existed)

Finally, verify that the <orphan_token> , with the expired parent <token_parent> , still exists:

```bash
vault token lookup <orphan_token>
```

Key                |Value
---                |-----
accessor           |cUvrGwjBNI1CNQakzWEZUAej
creation_time      |1683881878
creation_ttl       |3m
display_name       |token
entity_id          |n/a
expire_time        |2023-05-12T09:00:58.370382928Z
explicit_max_ttl   |0s
id                 |hvs.fWXNTRGWgOBuub3xGMBRnH5D
issue_time         |2023-05-12T08:57:58.370388328Z
meta               |<nil>
num_uses           |0
orphan             |true
path               |auth/token/create
policies           |[root]
renewable          |true
ttl                |1m9s
type               |service

## Task 5: Create a Token Role and Periodic Token

A common use case of periodic token is long-running processes where generation of a new token can interrupt the entire system flow. This task demonstrates the creation of a role and
periodic token for such long-running process.

Get help on auth/token path:

```bash
vault path-help auth/token
```

First, create a token role named, monitor . This role has default policy and token renewal period of 24 hours

```bash
vault write auth/token/roles/monitor allowed_policies="default" period="24h"
```

Success! Data written to: auth/token/roles/monitor

Now, create a token for role, monitor :

```bash
vault token create -role="monitor"
```

Key                 |Value
---                 |-----
token               |hvs.CAESIHaFpax7XgfTrB6XwoI3gc5_JmJygrxh83IEWiZCzqOoGh4KHGh2cy43VHFjZmpMYldLcnM5Uzk0ZHA2NFJybXc
token_accessor      |C06p0MT5sTV0smFZGWVEi0wd
token_duration      |24h
token_renewable     |true
token_policies      |["default"]
identity_policies   |[]
policies            |["default"]

> This token can be renewed multiple times indefinitely as long as it gets renewed before it expires

## Task 6: Enable Username & Password Auth Method

List the enabled authentication methods:

```bash
vault auth list
```

Path     |Type    |Accessor              |Description               |Version
----     |----    |--------              |-----------               |-------
token/   |token   |auth_token_c5ec3a0b   |token based credentials   |n/a

Userpass auth method allows users to login with username and password. Execute the CLI command to enable the userpass auth method

```bash
vault auth enable userpass
```

Success! Enabled userpass auth method at: userpass/

Create a user with the name student01 , password training with the default policies.

```bash
vault write auth/userpass/users/wescale01 password="training" policies="default"
```

Success! Data written to: auth/userpass/users/wescale01

Login with the user wescale01 and their password training .

```bash
vault login -method=userpass username=wescale01 password="training"
```

Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                   |Value
---                   |-----
token                 |hvs.CAESIJs_n8lYyWqcSS_kRdGoGPiOm3xYkieUjgwvpI75x9L9Gh4KHGh2cy44Qnd0a0lnNlZFZlpBTEZpb2VXQjN4ckc
token_accessor        |xNsD28lqoMaaCBSI9D0yvqbx
token_duration        |768h
token_renewable       |true
token_policies        |["default"]
identity_policies     |[]
policies              |["default"]
token_meta_username   |wescale01

Open UI and test your token or userpass

Log back as root

```bash
vault login $(grep 'Initial Root Token:' key.txt | awk '{print $NF}')
```

## Challenge: Generate batch tokens

* Task 1: Create a token of type batch with default policy attached, and its TTL is set to 360 seconds.
* Task 2: Enable another userpass auth method at userpass-batch path which generates a batch token upon a successful user authentication. Be sure to test and verify

## Clean Up

```bash
docker container rm -f $(docker container ls -aq)

sudo rm -rf vault01/
```