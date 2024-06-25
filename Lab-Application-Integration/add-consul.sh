#!/usr/bin/env bash

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