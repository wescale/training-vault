#!/usr/bin/env bash

wget https://releases.hashicorp.com/vault/1.15.3/vault_1.15.3_linux_amd64.zip
unzip vault_1.15.3_linux_amd64.zip
chmod +x vault
rm vault_1.15.3_linux_amd64.zip

sudo mv vault /usr/bin/

export VAULT_ADDR='http://127.0.0.1:8200' 

docker network create pg

docker container run --network pg  --cap-add IPC_LOCK --name server01 -d -p 8200:8200 -v $(pwd)/vault.hcl:/vault/config/vault.hcl -v $(pwd)/vault01/file:/vault/file hashicorp/vault:1.15.3 vault server -config=/vault/config/vault.hcl

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

wget https://releases.hashicorp.com/envconsul/0.13.1/envconsul_0.13.1_linux_amd64.zip
unzip envconsul_0.13.1_linux_amd64.zip
chmod +x envconsul
sudo mv envconsul /usr/bin/
rm envconsul_0.13.1_linux_amd64.zip

wget https://releases.hashicorp.com/consul-template/0.31.0/consul-template_0.31.0_linux_amd64.zip
unzip consul-template_0.31.0_linux_amd64.zip
chmod +x consul-template
sudo mv consul-template /usr/bin/
rm consul-template_0.31.0_linux_amd64.zip