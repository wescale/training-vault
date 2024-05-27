# Lab - Production Ready Cluster on Kubernetes

<walkthrough-tutorial-duration duration="20.0"></walkthrough-tutorial-duration>

## Description

* Task 1: Create HA Cluster - with Integrated storage
* Task 2: Join Node Members
* Task 3: Access Secret

What we will not do

> - Auto-Unseal via vault master + Secondary Vault
> 
> - PGP Init
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
openssl genrsa -out ${WORKDIR}/vault.key 2048
```

Create CSR

```bash
cat > ${WORKDIR}/vault-csr.conf <<EOF
[req]
default_bits = 2048
prompt = no
encrypt_key = yes
default_md = sha256
distinguished_name = kubelet_serving
req_extensions = v3_req
[ kubelet_serving ]
O = system:nodes
CN = system:node:*.${VAULT_K8S_NAMESPACE}.svc.${K8S_CLUSTER_NAME}
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = *.${VAULT_SERVICE_NAME}
DNS.2 = *.${VAULT_SERVICE_NAME}.${VAULT_K8S_NAMESPACE}.svc.${K8S_CLUSTER_NAME}
DNS.3 = *.${VAULT_K8S_NAMESPACE}
DNS.4 = *.${VAULT_K8S_NAMESPACE}.svc
IP.1 = 127.0.0.1
EOF
```

Generate CSR

```bash
openssl req -new -key ${WORKDIR}/vault.key -out ${WORKDIR}/vault.csr -config ${WORKDIR}/vault-csr.conf
```

Issue the certificate

```bash
cat > ${WORKDIR}/csr.yaml <<EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
   name: vault.svc
spec:
   signerName: kubernetes.io/kubelet-serving
   expirationSeconds: 8640000
   request: $(cat ${WORKDIR}/vault.csr|base64|tr -d '\n')
   usages:
   - digital signature
   - key encipherment
   - server auth
EOF
```

Send CSR & Approve CSR

```bash
kubectl create -f ${WORKDIR}/csr.yaml
kubectl certificate approve vault.svc
```

Confirm cert was issued

```bash
kubectl get csr vault.svc
```

Store secret into Kubernetes

```bash
kubectl get csr vault.svc -o jsonpath='{.status.certificate}' | openssl base64 -d -A -out ${WORKDIR}/vault.crt

kubectl config view \
--raw \
--minify \
--flatten \
-o jsonpath='{.clusters[].cluster.certificate-authority-data}' \
| base64 -d > ${WORKDIR}/vault.ca

kubectl create namespace $VAULT_K8S_NAMESPACE

kubectl create secret generic vault-ha-tls \
   -n $VAULT_K8S_NAMESPACE \
   --from-file=vault.key=${WORKDIR}/vault.key \
   --from-file=vault.crt=${WORKDIR}/vault.crt \
   --from-file=vault.ca=${WORKDIR}/vault.ca
```

Install Vault master

```bash
cat > ${WORKDIR}/overrides.yaml <<EOF
global:
   enabled: true
   tlsDisable: false
injector:
   enabled: true
server:
   extraEnvironmentVars:
      VAULT_CACERT: /vault/userconfig/vault-ha-tls/vault.ca
      VAULT_TLSCERT: /vault/userconfig/vault-ha-tls/vault.crt
      VAULT_TLSKEY: /vault/userconfig/vault-ha-tls/vault.key
   volumes:
      - name: userconfig-vault-ha-tls
        secret:
         defaultMode: 420
         secretName: vault-ha-tls
   volumeMounts:
      - mountPath: /vault/userconfig/vault-ha-tls
        name: userconfig-vault-ha-tls
        readOnly: true
   standalone:
      enabled: false
   affinity: ""
   ha:
      enabled: true
      replicas: 3
      raft:
         enabled: true
         setNodeId: true
         config: |
            ui = true
            listener "tcp" {
               tls_disable = 0
               address = "[::]:8200"
               cluster_address = "[::]:8201"
               tls_cert_file = "/vault/userconfig/vault-ha-tls/vault.crt"
               tls_key_file  = "/vault/userconfig/vault-ha-tls/vault.key"
               tls_client_ca_file = "/vault/userconfig/vault-ha-tls/vault.ca"
            }
            storage "raft" {
               path = "/vault/data"
            }
            disable_mlock = true
            service_registration "kubernetes" {}
EOF

helm install -n $VAULT_K8S_NAMESPACE $VAULT_HELM_RELEASE_NAME hashicorp/vault -f ${WORKDIR}/overrides.yaml
```

Verify your installation

```bash
kubectl -n $VAULT_K8S_NAMESPACE get pods
```

Init your vault instance `vault-0`

```bash
kubectl exec -n $VAULT_K8S_NAMESPACE vault-0 -- vault operator init \
    -key-shares=1 \
    -key-threshold=1 \
    -format=json > ${WORKDIR}/cluster-keys.json

jq -r ".unseal_keys_b64[]" ${WORKDIR}/cluster-keys.json

VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" ${WORKDIR}/cluster-keys.json)
```

Unseal Vault instace `vault-0`

```bash
kubectl exec -n $VAULT_K8S_NAMESPACE vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY
```

Export root token

```bash
export CLUSTER_ROOT_TOKEN=$(cat ${WORKDIR}/cluster-keys.json | jq -r ".root_token")
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

# then
vault operator raft join -address=https://vault-1.vault-internal:8200 -leader-ca-cert="$(cat /vault/userconfig/vault-ha-tls/vault.ca)" -leader-client-cert="$(cat /vault/userconfig/vault-ha-tls/vault.crt)" -leader-client-key="$(cat /vault/userconfig/vault-ha-tls/vault.key)" https://vault-0.vault-internal:8200

exit

kubectl exec -n $VAULT_K8S_NAMESPACE -ti vault-1 -- vault operator unseal $VAULT_UNSEAL_KEY
```


List raft peers

```bash
kubectl exec -n $VAULT_K8S_NAMESPACE vault-0 -- vault operator raft list-peers
```


Join & Unseal instace `vault-2`

```bash
kubectl exec -n $VAULT_K8S_NAMESPACE -it vault-2 -- /bin/sh  

# then
vault operator raft join -address=https://vault-2.vault-internal:8200 -leader-ca-cert="$(cat /vault/userconfig/vault-ha-tls/vault.ca)" -leader-client-cert="$(cat /vault/userconfig/vault-ha-tls/vault.crt)" -leader-client-key="$(cat /vault/userconfig/vault-ha-tls/vault.key)" https://vault-0.vault-internal:8200

exit

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

# then
vault auth enable kubernetes
vault write auth/kubernetes/config \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"

vault policy write internal-app - <<EOF
path "secret/data/tls/apitest" {
  capabilities = ["read"]
}
EOF

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

Configure an pod

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: busybox-vault
  labels:
    app: apitest
spec:
  selector:
    matchLabels:
      app: apitest
  replicas: 1
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: 'true'
        vault.hashicorp.com/role: 'internal-app'
        vault.hashicorp.com/ca-cert: "/run/secrets/kubernetes.io/serviceaccount/ca.crt"
        vault.hashicorp.com/agent-inject-secret-config.txt: 'secret/data/tls/apitest'
        vault.hashicorp.com/agent-inject-template-config.txt: |
          {{- with secret "secret/data/tls/apitest" -}}
          http://{{ .Data.data.username }}:{{ .Data.data.password }}@toto.com
          {{- end -}}
      labels:
        app: apitest
    spec:
      containers:
      - name: busybox
        image: busybox
        args:
        - sleep
        - "10000"
EOF
```

Check logs

```bash
kubectl logs \
    $(kubectl get pod -l app=apitest -o jsonpath="{.items[0].metadata.name}") \
    --container vault-agent-init
```

Patch your deployment

```bash
cat <<EOF > ${WORKDIR}/patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: busybox-vault
  labels:
    app: apitest
spec:
  template:
    spec:
      # This service account does not have permission to request the secrets.
      serviceAccountName: internal-app

EOF

kubectl patch deployment busybox-vault --patch-file ${WORKDIR}/patch.yaml
```

kubectl exec -it busybox-vault-576c5cc4cb-hr6jw -c busybox -- cat /vault/secrets/config.txt


kubectl exec -n $VAULT_K8S_NAMESPACE -ti vault-0 -- vault kv put secret/tls/apitest username="apiuser" password="supersecret2"

## Clean Up (only at the end of the training)

Regenerate certs

```bash
kubectl delete -f ${WORKDIR}/csr.yaml
```

Restart an instance (ie: vault-0)

```bash
kubectl exec -n $VAULT_K8S_NAMESPACE -ti vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY

export CLUSTER_ROOT_TOKEN=$(cat ${WORKDIR}/cluster-keys.json | jq -r ".root_token")
kubectl exec -n $VAULT_K8S_NAMESPACE vault-0 -- vault login $CLUSTER_ROOT_TOKEN 
kubectl exec -n $VAULT_K8S_NAMESPACE vault-0 -- vault operator raft list-peers
```