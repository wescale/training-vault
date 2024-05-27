#!/usr/bin/env bash

export VAULT_ADDR='http://127.0.0.1:8200' 

docker network create pg

docker container run --network pg  --cap-add IPC_LOCK --name server01 -d -p 8200:8200 -v $(pwd)/vault.hcl:/vault/config/vault.hcl -v $(pwd)/vault01/file:/vault/file hashicorp/vault:1.16.2 vault server -config=/vault/config/vault.hcl

docker container run --network pg -d --name postgres -e POSTGRES_PASSWORD="password" postgres

docker network connect pg server01
docker network connect pg postgres

sleep 5
vault operator init -key-shares=1 -key-threshold=1 > key.txt

sleep 2

vault operator unseal $(grep 'Key 1:' key.txt | awk '{print $NF}')

sleep 2

vault login $(grep 'Initial Root Token:' key.txt | awk '{print $NF}')

sudo mkdir -p vault01/file/audit
sudo chown -R 100:1000 vault01/file/audit

vault audit enable file file_path=/vault/file/audit/audit.log