#!/usr/bin/env bash

wget wget https://github.com/derailed/k9s/releases/download/v0.29.1/k9s_Linux_amd64.tar.gz
tar xvf v0.29.1/k9s_Linux_amd64.tar.gz
chmod +x k9s
mv k9s /usr/bin
rm v0.29.1/k9s_Linux_amd64.tar.gz

source <(kubectl completion bash) # set up autocomplete in bash into the current shell, bash-completion package should be installed first.
echo "source <(kubectl completion bash)" >> ~/.bashrc # add autocomplete permanently to your bash shell.

alias k=kubectl
complete -o default -F __start_kubectl k