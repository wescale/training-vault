#!/usr/bin/env bash

wget https://releases.hashicorp.com/vault/1.16.2/vault_1.16.2_linux_amd64.zip
unzip vault_1.16.2_linux_amd64.zip
chmod +x vault

sudo mv vault /usr/bin/
vault version

rm -f vault_1.16.2_linux_amd64.zip