# Lab 06 - Vault Operations

<walkthrough-tutorial-duration duration="40.0"></walkthrough-tutorial-duration>

## Description

* Task 1: Generate a root token
* Task 2: Rekeying Vault
* Task 3: Rotate the encryption key


## Init Lab

```bash
chmod +x vault.sh
./vault.sh
```


```bash
export VAULT_ADDR='http://127.0.0.1:8200' 

vault secrets list -detailed
```

## Task 1: Generate a root token

Check command helper

```bash
vault operator generate-root -h
```

Generate OTP and save to otp.txt

```bash
vault operator generate-root -generate-otp > otp.txt
```

Generate a root token generation with this OTP and save result in nonce.txt

```bash
vault operator generate-root -init -otp=$(cat otp.txt) -format=json \
| jq -r ".nonce" > nonce.txt
```

> Nonce have to be distribued to all unseal key admins

```bash
vault operator generate-root -nonce=$(cat nonce.txt) $(grep 'Key 1:' key.txt | awk '{print $NF}')
```

  - | -
--- | ---
Nonce           |4efc1fa4-4ad9-18c2-15a9-460a798a6808
Started         |true
Progress        |1/1
Complete        |true
Encoded|Token   |DSUVFiR4FAISYhtiHDlZPwYqBh8/CiItCgseKw

Decode the encoded token

```bash
vault operator generate-root -decode=DSUVFiR4FAISYhtiHDlZPwYqBh8/CiItCgseKw \
-otp=$(cat otp.txt)
```

Login with your new token


Key                 |Value
---                 |-----
token               |hvs.e1wDB8T6tR5eRx5wEPWGoaxE
token_accessor      |bMbdBTpaoPX3XVEAbZxIQci6
token_duration      |∞
token_renewable     |false
token_policies      |["root"]
identity_policies   |[]
policies            |["root"]

## Task 2: Rekeying Vault

During the initialization, the encryption keys and unseal keys were generated. This only happens once when the server is started against a new backend that has never been used with Vault before.
Under some circumstances, you may want to re-generate the master key and key shares. For examples:

- Someone joins or leaves the organization
- Security wants to change the number of shares or threshold of shares
- Compliance mandates the master key be rotated at a regular interval

```bash
vault operator rekey -init -key-shares=3 -key-threshold=2 \
-format=json | jq -r ".nonce" > nonce.txt
```

Because we have only one key

```bash
vault operator rekey -nonce=$(cat nonce.txt) $(grep 'Key 1:' key.txt | awk '{print $NF}')
```

## Task 3: Rotate the encryption key

In Vault, rekeying and rotating are two separate operations. The process for generating a new master key and applying Shamir's algorithm is called "rekeying". The process for generating a new encryption key for
Vault to encrypt data at rest is called "rotating".

Unlike rekeying the Vault, rotating Vault's encryption key does not require a quorum of unseal keys. Anyone with the proper permissions in Vault can perform the encryption key rotation.
To trigger a key rotation, execute the following command:

```bash
vault operator rotate
```


## Clean Up

```bash
docker container rm -f $(docker container ls -aq)
```

```bash
sudo rm -rf vault01/
```