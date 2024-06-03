#!/usr/bin/env bash

export VAULT_ADDR='http://127.0.0.1:8200' 

sleep 2

vault operator unseal $(grep 'Key 1:' ../vault-key.txt | awk '{print $NF}') || true

sleep 2

vault login $(grep 'Initial Root Token:' ../vault-key.txt | awk '{print $NF}')
