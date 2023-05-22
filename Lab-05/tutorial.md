# Lab 05 - Cubbyhole Secret Engine

<walkthrough-tutorial-duration duration="20.0"></walkthrough-tutorial-duration>

## Description

* Task 1: Test the cubbyhole secret engine using CLI
* Task 2: Trigger response wrapping
* Task 3: Unwrap the wrapped Secret
* Task 4: Response wrapping via the web UI


## Init Lab

```bash
chmod +x vault.sh
./vault.sh
```

Test your Vault

```bash
export VAULT_ADDR='http://127.0.0.1:8200' 

vault secrets list -detailed
```

## Task 1: Test the cubbyhole secret engine using CLI

Create a non-privileged token <connexion_token>

```bash
vault token create -policy=default
```

Key                 |Value
---                 |-----
token               |hvs.CAESIBNLdHREmz8IPV6O6eMbSkk46PGF78Ki4XYD2EptqAIGGh4KHGh2cy5UU2huMEltRWtFQmlRQldyMFo0UlhpMDI
token_accessor      |Yr4GpxxFVVJ7I80kKDPpqJ2K
token_duration      |768h
token_renewable     |true
token_policies      |["default"]
identity_policies   |[]
policies            |["default"]

Open a new shell then switch user (for example switch to root) and login to vault with non-priviliged token <connexion_token>:

```bash

sudo su

export VAULT_ADDR='http://127.0.0.1:8200' 

vault login hvs.CAESIBNLdHREmz8IPV6O6eMbSkk46PGF78Ki4XYD2EptqAIGGh4KHGh2cy5UU2huMEltRWtFQmlRQldyMFo0UlhpMDI
```

Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                 |Value
---                 |-----
token               |hvs.CAESIBNLdHREmz8IPV6O6eMbSkk46PGF78Ki4XYD2EptqAIGGh4KHGh2cy5UU2huMEltRWtFQmlRQldyMFo0UlhpMDI
token_accessor      |Yr4GpxxFVVJ7I80kKDPpqJ2K
token_duration      |767h58m29s
token_renewable     |true
token_policies      |["default"]
identity_policies   |[]
policies            |["default"]

Store a secret to your private cubbyhole path

```bash
vault write cubbyhole/private mobile="123-456-7890"
```

Read the secret

```bash
vault read cubbyhole/private
```

Return to the previous shell then try to read same secret
No value found at cubbyhole/private

## Task 2: Trigger response wrapping

Left sudo su

```bash
exit
```

Create a response wrapping to secret/wescale

```bash

vault secrets enable -path secret kv-v2

vault kv put secret/wescale company="wescale"

vault kv get -wrap-ttl=360 secret/wescale
```

Key                             |Value
---                             |-----
wrapping_token:                 |hvs.CAESII0xgMCYqdFUtuLP2kzR55H-ZTpeD1BXikGFod_8XNnlGh4KHGh2cy5HUjdMakM2Q1B3Y1N2R21kUmpkMDFWSUc
wrapping_accessor:              |DqpseDHVu8ulRT43juRlL8gA
wrapping_token_ttl:             |6m
wrapping_token_creation_time:   |2023-03-31|14:39:06.778469946 +0000|UTC
wrapping_token_creation_path:   |secret/data/wescale

## Task 3: Unwrap the wrapped Secret


Open a new shell then switch user (for example switch to root) and login to vault with non-priviliged token <connexion_token>:

```bash

sudo su

export VAULT_ADDR='http://127.0.0.1:8200' 

vault login hvs.CAESIBNLdHREmz8IPV6O6eMbSkk46PGF78Ki4XYD2EptqAIGGh4KHGh2cy5UU2huMEltRWtFQmlRQldyMFo0UlhpMDI
```

Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                 |Value
---                 |-----
token               |hvs.CAESIBNLdHREmz8IPV6O6eMbSkk46PGF78Ki4XYD2EptqAIGGh4KHGh2cy5UU2huMEltRWtFQmlRQldyMFo0UlhpMDI
token_accessor      |Yr4GpxxFVVJ7I80kKDPpqJ2K
token_duration      |767h58m29s
token_renewable     |true
token_policies      |["default"]
identity_policies   |[]
policies            |["default"]

Try to read secret/wescale

```bash
vault kv get secret/wescale
```
Error making API request.

URL: GET http://127.0.0.1:8200/v1/sys/internal/ui/mounts/secret/wescale
Code: 403. Errors:

* preflight capability check returned 403, please ensure client's policies grant access to path "secret/wescale/"

Unwrap with `wrapping_token`

```bash
vault unwrap hvs.CAESII0xgMCYqdFUtuLP2kzR55H-ZTpeD1BXikGFod_8XNnlGh4KHGh2cy5HUjdMakM2Q1B3Y1N2R21kUmpkMDFWSUc
```

What happens if no one use the token before expired period or already use the token ?

## Task 4: Response wrapping via the web UI


## Clean Up

```bash
docker container rm -f $(docker container ls -aq)

sudo rm -rf vault01/
```