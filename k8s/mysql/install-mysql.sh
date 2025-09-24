#!/usr/bin/env bash

# Garante que o script pare em caso de erro
set -eo pipefail

# --- Variáveis de Configuração ---
NAMESPACE="mysql-cluster"
SECRET_NAME="mypwds"
CLUSTER_MANIFEST="mycluster.yaml" # Nome do arquivo que define seu InnoDBCluster
OPERATOR_NAMESPACE="mysql-operator" # Namespace padrão do operator

# --- Cores para o output ---
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
NO_COLOR='\033[0m'

# --- Início da Execução ---

printf "%bPasso 1: Instalando os CRDs e o MySQL Operator...%b\n" "$GREEN" "$NO_COLOR"
# Instala as definições de recursos (CRDs) que o operator precisa
kubectl apply -f https://raw.githubusercontent.com/mysql/mysql-operator/trunk/deploy/deploy-crds.yaml
# Instala o Deployment do Operator em si no namespace 'mysql-operator'
kubectl apply -f https://raw.githubusercontent.com/mysql/mysql-operator/trunk/deploy/deploy-operator.yaml

printf "\n%bPasso 2: Aguardando o MySQL Operator ficar pronto...%b\n" "$ORANGE" "$NO_COLOR"
# Esta é a etapa crucial: esperamos o deployment do operator estar 'available'
# antes de prosseguir. O timeout evita que o script fique preso indefinidamente.
kubectl wait --for=condition=available deployment/mysql-operator \
  --namespace "$OPERATOR_NAMESPACE" \
  --timeout=5m

printf "\n%bPasso 3: Criando o namespace e o secret para o cluster MySQL...%b\n" "$GREEN" "$NO_COLOR"
# O 'apply' garante que o comando não falhe se o namespace já existir
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $NAMESPACE
EOF

# O 'apply' também funciona para secrets se usarmos a flag --dry-run e o formato yaml
# Isso torna a criação do secret idempotente.
kubectl create secret generic "$SECRET_NAME" -n "$NAMESPACE" \
        --from-literal=rootUser=root \
        --from-literal=rootHost=% \
        --from-literal=rootPassword="sakila" \
        --dry-run=client -o yaml | kubectl apply -f -

printf "\n%bPasso 4: Criando o InnoDBCluster a partir do arquivo '%s'...%b\n" "$GREEN" "$CLUSTER_MANIFEST" "$NO_COLOR"
# Aplica o seu manifesto do InnoDBCluster
kubectl apply -f "$CLUSTER_MANIFEST"

printf "\n%bPasso 5: Monitorando a criação do cluster. Pressione Ctrl+C para sair.%b\n" "$ORANGE" "$NO_COLOR"
# O comando 'get --watch' é ótimo para monitorar o status em tempo real
kubectl get innodbcluster -n "$NAMESPACE" --watch

printf "\n%b[SUCESSO] Instalação do MySQL InnoDBCluster iniciada.%b\n" "$GREEN" "$NO_COLOR"
