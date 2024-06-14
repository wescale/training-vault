# Lab - Production Ready Cluster on Kubernetes

<walkthrough-tutorial-duration duration="20.0"></walkthrough-tutorial-duration>

## Description

* Task 1: Create HA Cluster - with Integrated storage
* Task 2: Join Node Members
* Task 3: Access Secret

What we will not do

> - Auto-Unseal via vault master + Secondary Vault (install another vault in other NS/Cluster or use cloud KMS )
> 
> - PGP Init (required for prod env)
> 
> - Vautl CSI
> 
> - Ingress

## Init Lab

Verify the connection to your Kubernetes cluster

```bash
kubectl get nodes
```

Prepare Helm 

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

helm search repo hashicorp/vault
```

## Task 1: Setup Auto-Unseal server - HA

Init your folder

```bash
mkdir -p tmp/vault

export VAULT_K8S_NAMESPACE="vault-master" \
export VAULT_HELM_RELEASE_NAME="vault" \
export VAULT_SERVICE_NAME="vault-internal" \
export K8S_CLUSTER_NAME="cluster.local" \
export WORKDIR=$(pwd)/tmp/vault

```

Generate certificate private key

```bash
openssl genrsa -out ${WORKDIR}/files/vault.key 2048
```

Create CSR

```bash
cat ${WORKDIR}/files/vault-csr.conf
```

Generate CSR

```bash
openssl req -new -key ${WORKDIR}/files/vault.key -out ${WORKDIR}/files/vault.csr -config ${WORKDIR}/files/vault-csr.conf
```

Issue the certificate

```bash
cat ${WORKDIR}/files/csr.yaml 
```

Send CSR & Approve CSR

```bash
kubectl create -f ${WORKDIR}/files/csr.yaml
kubectl certificate approve vault.svc
```

Confirm cert was issued

```bash
kubectl get csr vault.svc
```

Store secret into Kubernetes

Extract certificate

```bash
kubectl get csr vault.svc -o jsonpath='{.status.certificate}' | openssl base64 -d -A -out ${WORKDIR}/files/vault.crt
```

Extract CA
```bash
kubectl config view \
--raw \
--minify \
--flatten \
-o jsonpath='{.clusters[].cluster.certificate-authority-data}' \
| base64 -d > ${WORKDIR}/files/vault.ca
```

Create vault NS
```bash
kubectl create namespace $VAULT_K8S_NAMESPACE
```

Create kubernetes generic secret
```bash
kubectl create secret generic vault-ha-tls \
   -n $VAULT_K8S_NAMESPACE \
   --from-file=vault.key=${WORKDIR}/files/vault.key \
   --from-file=vault.crt=${WORKDIR}/files/vault.crt \
   --from-file=vault.ca=${WORKDIR}/files/vault.ca
```

Install Vault master

Check `overrides.yaml`

```bash
cat ${WORKDIR}/files/overrides.yaml
```

```bash
helm install -n $VAULT_K8S_NAMESPACE $VAULT_HELM_RELEASE_NAME hashicorp/vault -f ${WORKDIR}/files/overrides.yaml
```

Verify your installation

```bash
kubectl -n $VAULT_K8S_NAMESPACE get pods -w
```

Init your vault instance `vault-0`

```bash
kubectl exec -n $VAULT_K8S_NAMESPACE vault-0 -- vault operator init \
    -key-shares=1 \
    -key-threshold=1 \
    -format=json > ${WORKDIR}/files/cluster-keys.json

jq -r ".unseal_keys_b64[]" ${WORKDIR}/files/cluster-keys.json

VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" ${WORKDIR}/files/cluster-keys.json)
```

Unseal Vault instace `vault-0`

```bash
kubectl exec -n $VAULT_K8S_NAMESPACE vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY
```

Export root token

```bash
export CLUSTER_ROOT_TOKEN=$(cat ${WORKDIR}/files/cluster-keys.json | jq -r ".root_token")
```

Activate audit log

```bash
kubectl exec -n $VAULT_K8S_NAMESPACE vault-0 -- vault login $CLUSTER_ROOT_TOKEN 

kubectl exec -n $VAULT_K8S_NAMESPACE vault-0 -- vault audit enable file file_path=/vault/data/audit.log
```

## Task 2: Join members

Join & Unseal instace `vault-1`

```bash
kubectl exec -n $VAULT_K8S_NAMESPACE -it vault-1 -- /bin/sh 
```

```bash
# then
vault operator raft join -address=https://vault-1.vault-internal:8200 -leader-ca-cert="$(cat /vault/userconfig/vault-ha-tls/vault.ca)" -leader-client-cert="$(cat /vault/userconfig/vault-ha-tls/vault.crt)" -leader-client-key="$(cat /vault/userconfig/vault-ha-tls/vault.key)" https://vault-0.vault-internal:8200

exit
```

Unseal

```bash
kubectl exec -n $VAULT_K8S_NAMESPACE -ti vault-1 -- vault operator unseal $VAULT_UNSEAL_KEY
```


List raft peers

```bash
kubectl exec -n $VAULT_K8S_NAMESPACE vault-0 -- vault operator raft list-peers
```


Join & Unseal instace `vault-2`

```bash
kubectl exec -n $VAULT_K8S_NAMESPACE -it vault-2 -- /bin/sh  
```

```bash
# then
vault operator raft join -address=https://vault-2.vault-internal:8200 -leader-ca-cert="$(cat /vault/userconfig/vault-ha-tls/vault.ca)" -leader-client-cert="$(cat /vault/userconfig/vault-ha-tls/vault.crt)" -leader-client-key="$(cat /vault/userconfig/vault-ha-tls/vault.key)" https://vault-0.vault-internal:8200

exit
```

```bash
kubectl exec -n $VAULT_K8S_NAMESPACE -ti vault-2 -- vault operator unseal $VAULT_UNSEAL_KEY
```


List raft peers

```bash
kubectl exec -n $VAULT_K8S_NAMESPACE vault-0 -- vault operator raft list-peers
```

Test your setup 

```bash
kubectl exec -n $VAULT_K8S_NAMESPACE vault-0 -- vault status
```


## Task 3: Access Secret

Create K/V Secret engine

```bash
kubectl exec -n $VAULT_K8S_NAMESPACE -ti vault-0 -- vault secrets enable -path=secret kv-v2
```

Set secret

```bash
kubectl exec -n $VAULT_K8S_NAMESPACE -ti vault-0 -- vault kv put secret/tls/apitest username="apiuser" password="supersecret"
```

Access secret through external

In a new terminal

```bash
kubectl -n $VAULT_K8S_NAMESPACE port-forward service/vault 8200:8200
```

In the previous terminal

```bash
curl --cacert $WORKDIR/vault.ca \
   --header "X-Vault-Token: $CLUSTER_ROOT_TOKEN" \
   https://127.0.0.1:8200/v1/secret/data/tls/apitest | jq .data.data
```

Configure Kubernetes agent injector

```bash
kubectl exec -n $VAULT_K8S_NAMESPACE -it vault-0 -- /bin/sh  
```

```bash
# then
vault auth enable kubernetes
vault write auth/kubernetes/config \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"
```

```bash
vault policy write internal-app - <<EOF
path "secret/data/tls/apitest" {
  capabilities = ["read"]
}
EOF
```

```bash
vault write auth/kubernetes/role/internal-app \
    bound_service_account_names=internal-app \
    bound_service_account_namespaces=default \
    policies=internal-app \
    ttl=24h

exit
```

Configure service account

```bash
kubectl create sa internal-app
kubectl get serviceaccounts
```

Configure a pod

```bash
cat ${WORKDIR}/files/pod.yaml 
```

```bash
kubectl apply -f  ${WORKDIR}/files/pod.yaml 
```

Check logs

```bash
kubectl logs \
    $(kubectl get pod -l app=apitest -o jsonpath="{.items[0].metadata.name}") \
    --container vault-agent-init
```

Patch your deployment

```bash
cat ${WORKDIR}/files/patch.yaml
```

```bash
kubectl patch deployment busybox-vault --patch-file ${WORKDIR}/patch.yaml
```

Check your secret

```bash
kubectl exec -it busybox-vault-576c5cc4cb-hr6jw -c busybox -- cat /vault/secrets/config.txt
```

Modify secret

```bash
kubectl exec -n $VAULT_K8S_NAMESPACE -ti vault-0 -- vault kv put secret/tls/apitest username="apiuser" password="supersecret2"
```

Check your secret again

```bash
kubectl exec -it busybox-vault-576c5cc4cb-hr6jw -c busybox -- cat /vault/secrets/config.txt
```


## Clean Up (only at the end of the training)

Regenerate certs

```bash
kubectl delete -f ${WORKDIR}/files/csr.yaml
kubectl delete ns $VAULT_K8S_NAMESPACE
```

## Troubleshoot

Restart an instance (ie: vault-0)

```bash
kubectl exec -n $VAULT_K8S_NAMESPACE -ti vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY

export CLUSTER_ROOT_TOKEN=$(cat ${WORKDIR}/cluster-keys.json | jq -r ".root_token")
kubectl exec -n $VAULT_K8S_NAMESPACE vault-0 -- vault login $CLUSTER_ROOT_TOKEN 
kubectl exec -n $VAULT_K8S_NAMESPACE vault-0 -- vault operator raft list-peers
```