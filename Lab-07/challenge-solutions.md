# Lab 07 - Vault Authentication and Tokens

## Challenge: Generate batch tokens

### Task 1: Solution

Create a batch token with default policy attached, and its TTL is set to 360 seconds.

```bash
vault token create -type=batch -policy=default -ttl=360
```

Key                 |Value
---                 |-----
token               |hvb.AAAAAQL9uCqMw50GuVd_bC4lSihtRGyIdKrxAq4DKPSgy-HX4wJ1v9O5sF6J1DuDZfoPHaekgIS7Kl-TbXp8PR1x7tOkDNJM7zdnhKPlMn3hkmZv2MioFQULyjzMVYoloAIj4l1SVzOtrs96NwogrDFzPqmPpiZHeQ
token_accessor      |n/a
token_duration      |6m
token_renewable     |false
token_policies      |["default"]
identity_policies   |[]
policies            |["default"]

### Task 2: Solution

Enable another userpass auth mehod at 'userpass-batch' which generates batch tokens.

```bash
vault auth enable -path="userpass-batch" -token-type=batch userpass
```
Success! Enabled userpass auth method at: userpass-batch/

```bash
vault auth list
```

Create a user called 'john' with the password 'training':

```bash
vault write auth/userpass-batch/users/john password="training" policies="default"
```

Authenticate as 'john' to verify its generate token type The token should starts with 'b.'

```bash
vault login -method=userpass -path="userpass-batch" username="john" password="training"
```

Key                   |Value
---                   |-----
token                 |hvb.AAAAAQJMnoehSZqkatz0QR-sCtXHwQuH4cXHoCkXXuj8o5cLHiT3cUJZSFrXReeb5razhH2XPwDH2ZvBBe7rtKUqGt5SWQglb57mCZ9ZIFP6TJ32_j9wXVwuWTb-ldRMstplo85f59jxuxuF_5KLfRi-GK-7iuMQZjIGuHNVnT2eXenof8l0s4rJ56YOX4WtiElfQH7htwYLTWvSMeJ_kogoP_h5IEviNB8SR0dMxQ4
token_accessor        |n/a
token_duration        |768h
token_renewable       |false
token_policies        |["default"]
identity_policies     |[]
policies              |["default"]
token_meta_username   |john
