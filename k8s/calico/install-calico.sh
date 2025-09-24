#!/usr/bin/env bash

# Garante que o script pare em caso de erro e trate pipes corretamente
set -eo pipefail

# --- Variáveis de Configuração ---
# Centralize a versão aqui para facilitar futuras atualizações
CALICO_VERSION="v3.30.3"

# URLs dos manifestos
OPERATOR_CRDS_URL="https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/operator-crds.yaml"
TIGERA_URL="https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/tigera-operator.yaml"
CUSTOM_RESOURCES_URL="https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/custom-resources.yaml"

# Namespace onde o operator será instalado
TIGERA_NAMESPACE="tigera-operator"

# --- Cores para o output ---
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
NO_COLOR='\033[0m'

printf "%bInstalando Calico Operator (versão %s)...%b\n" "$GREEN" "$CALICO_VERSION" "$NO_COLOR"

# Passo 1: Aplicar os CRDs (Custom Resource Definitions) do Operator
printf "%s\n" "-> Aplicando CRDs do Operator..."
kubectl create -f "${OPERATOR_CRDS_URL}"

# Passo 2: Aplicar o manifesto do Tigera Operator
printf "%s\n" "-> Aplicando o manifesto do Tigera Operator..."
kubectl create -f "${TIGERA_URL}"

# Passo 3: Esperar o deployment do operator ficar pronto
printf "\n%bAguardando o Operator do Calico ficar pronto...%b\n" "$ORANGE" "$NO_COLOR"
sleep 10

# Passo 4: Aplicar os recursos customizados (a configuração do Calico)
printf "\n%bAplicando a configuração customizada do Calico...%b\n" "$GREEN" "$NO_COLOR"
kubectl create -f "${CUSTOM_RESOURCES_URL}"

# Linha modificada abaixo
printf "\n%b[SUCESSO] Calico instalado com sucesso!%b\n" "$GREEN" "$NO_COLOR"

