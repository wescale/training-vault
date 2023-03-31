# Lab 04 - Transit Secret Engine

<walkthrough-tutorial-duration duration="25.0"></walkthrough-tutorial-duration>

## Description

Task 1: Configure transit secret engine
Task 2: Encrypt secrets
Task 3: Decrypt a cipher-text
Task 4: Rotate the encryption Key
Task 5: Update the key configuration
Task 6: Encrypt data via web UI

Challenge: Sign and validate data

## Init Lab

chmod +x vault.sh
./vault.sh
export VAULT_ADDR='http://127.0.0.1:8200' 

vault secrets list -detailed

## Task 1: Configure transit secret engine

Enable transit secret engine

```bash
vault secrets enable transit
```

Create an encryption key ring named cards

```bash
vault write -f transit/keys/cards
```

## Task 2: Encrypt Secrets

Any client with valid token (with proper permission) can send data (base64 encoded) to encrypt

```bash
vault write transit/encrypt/cards plaintext=$(base64 <<< "credit-card-number")
```

Key            Value
---            -----
ciphertext     vault:v1:x7B0eKS9JWnJ07rdNGb9gqSjqBnyUefvRy5IGAYgH0g509BxURetCZRSxwObFO8=
key_version    1

## Task 3: Decode Secrets

Any client with valid token (with proper permission) can decrypt data (as base64 encoded)

```bash
vault write transit/decrypt/cards \
ciphertext="vault:v1:x7B0eKS9JWnJ07rdNGb9gqSjqBnyUefvRy5IGAYgH0g509BxURetCZRSxwObFO8="
```

Key          Value
---          -----
plaintext    Y3JlZGl0LWNhcmQtbnVtYmVyCg==

Decode base64 encoded info

```bash
base64 -d <<< "Y3JlZGl0LWNhcmQtbnVtYmVyCg=="
```

## Task 4: Rotate the encryption Key

> Key can be rotate easily by a human or an automated process.

Rotate the key

```bash
vault write -f transit/keys/cards/rotate
```

Create a new secret (plaintext: `visa-card-number`)

```bash
vault write transit/encrypt/cards plaintext=$(base64 <<< "visa-card-number")
```

Key            Value
---            -----
ciphertext     vault:v2:TEPjRCXHZvWg4ctAFgsSBJG6j08jFNR+z3c2ImlVpidQ8G2kaR4sPxcWLBVm
key_version    2

Compare ciphers

| cipher 1 | cipher 2 |
|---|---|
| `vault:v1:` | `vault:v2:` |

Rewrap you first cipher

```bash
vault write transit/rewrap/cards ciphertext="vault:v1:x7B0eKS9JWnJ07rdNGb9gqSjqBnyUefvRy5IGAYgH0g509BxURetCZRSxwObFO8="
```

Key            Value
---            -----
ciphertext     vault:v2:OIUuCbtyxM3sFsbSfbaFhdHnchum19aDSgBtGHZhpN0dM686LucmHhYDwb1cyvc=
key_version    2


## Task 5: Update the key configuration

Rotate your key multiple times

```bash
vault write -f transit/keys/cards/rotate
```

Read your key information

```bash
vault read transit/keys/cards
```

Enforce key at version 6

```bash
vault write transit/keys/cards/config min_decryption_version=6
vault read transit/keys/cards
```

Try to rewrap your cipher

```bash
vault write transit/rewrap/cards ciphertext="vault:v1:x7B0eKS9JWnJ07rdNGb9gqSjqBnyUefvRy5IGAYgH0g509BxURetCZRSxwObFO8="
```

Error writing data to transit/rewrap/cards: Error making API request.
* ciphertext or signature version is disallowed by policy (too old)

## Task 6: Encrypt data via web UI



## Challenge: Setup database secret engine via API



## Clean Up

```bash
docker container rm -f $(docker container ls -aq)

sudo rm -rf vault01/
```