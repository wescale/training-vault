# Lab 08 - Vault policies

<walkthrough-tutorial-duration duration="30.0"></walkthrough-tutorial-duration>

## Description

* Task 1: Create a Policy
* Task 2: Test the "base" Policy
* Task 3: Check the token capabilities

* Challenge: Create and Test Policies


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

## Task 1: Create a policy

In reality, first, you gather policy requirements, and then author policies to meet the requirements. In this task, you are going to write an ACL policy (in HCL format), and then create a policy in Vault.

Let's create the policy file, policies/base.hcl

```bash
cat <<EOF > policies/base.hcl
path "kv/data/training_*" {
  capabilities = ["create", "read"]
}

path "kv/data/+/apikey" {
  capabilities = ["create", "read", "update", "delete"]
}
EOF
```

Get help for the vault policy command:

```bash
vault policy -h
```

Execute the following CLI command to list existing policy names:

```bash
vault policy write base policies/base.hcl
```

Success! Uploaded policy: base

Execute the following CLI command to list existing policy names:

```bash
vault policy list
```

base
default
root

To read back the base policy, execute the following command:

```bash
vault policy read base
```

Enabled Key/Value v2 secrets engine at kv path by executing the following command:

```bash
vault secrets enable -path=kv/ kv-v2
```

Success! Enabled the kv-v2 secrets engine at: kv/

Create a token attached to the newly created base policy so that you can test it. Execute the following commands to create a new token:

```bash
vault token create -policy="base"
```

Key                 |Value
---                 |-----
token               |hvs.CAESIPlTKMW2ggo-yVwOnQpwGhC_OFUbugHhywKg7fD92TguGh4KHGh2cy5xdWJKbnhqcDBSeDFsWDVmOWZTQW5yWnM
token_accessor      |rOOLesIwKK3rPESZIQCn4NGe
token_duration      |767h59m48s
token_renewable     |true
token_policies      |["base" "default"]
identity_policies   |[]
policies            |["base" "default"]

Login with token previous created

```bash
vault login <token>
```

## Task 2: Test the "base" Policy

Using the base token, you have very limited permissions.

```bash
vault policy list
```

Error listing policies: Error making API request.

URL: GET http://127.0.0.1:8200/v1/sys/policies/acl?list=true
Code: 403. Errors:

* 1 error occurred:
        * permission denied

> The base policy does not have a rule on sys/policy path. Lack of policy means no permission on that path. Therefore, returning the permission denied error is the expected behavior

Now, try writing data to a proper path that the base policy allows.

```bash
vault kv put kv/training_test password="p@ssw0rd"
```

Read the data back:

```bash
vault kv get kv/training_test
```

Pass a different password value to update it.

```bash
vault kv put kv/training_test password="password1234"
```

Error writing data to kv/data/training_test: Error making API request.

URL: PUT http://127.0.0.1:8200/v1/kv/data/training_test
Code: 403. Errors:

* 1 error occurred:
        * permission denied

> This should fail because the base policy only grants "create" and "read". With absence of "update" permission, this operation fails.

Execute the following command:

```bash
vault kv put kv/team-eng/apikey api_key="123456789"
```

Since the policy allows delete operation, the following command should execute successfully as well:

```bash
vault kv delete kv/team-eng/apikey
```

Success! Data deleted (if it existed) at: kv/data/team-eng/apikey

Question
What happens when you try to write data in kv/training_ path?
Execute

```bash
vault kv put kv/training_ year="2023"
```

## Task 3: Check the token capabilities

Let's view the help message for the token capabilities command:

```bash
vault token capabilities -h
```

Execute the capabilities command to check permissions on kv/data/training_dev path

```bash
vault token capabilities kv/data/training_dev
```

How about kv/data/splunk/apikey path?

```bash
vault token capabilities kv/data/splunk/apikey
```

Try another path that is **NOT** permitted by the base policy:

```bash
vault token capabilities kv/data/test
```

Log back as root

## Challenge: 

Policy Requirements:

1. Permits create, read, and update anything in paths prefixed with kv/data/exercise
2. Forbids any operation against kv/data/exercise/team-admin (this is an exception to the requirement #1)
3. Forbids deleting anything in paths prefixed with kv/data/exercise
4. List existing policies (CLI command: vault policy list)
5. View available auth methods (CLI command: vault auth list)


> You should remember is -output-curl-string CLI flag. For example, to find out the cURL equivalent of API call:
> 
> cURL equivalent for vault policy list :

```bash
vault policy list -output-curl-string
```

> cURL equivalent for vault auth list

```bash
vault auth list -output-curl-string
```

[Challenge Solution](challenge-solution.md)

## Clean Up

```bash
docker container rm -f $(docker container ls -aq)

sudo rm -rf vault01/
```