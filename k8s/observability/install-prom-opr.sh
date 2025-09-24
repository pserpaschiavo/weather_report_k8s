#!/usr/bin/env bash

# Garante que o script pare em caso de erro
set -eo pipefail

# Obtém o diretório do script para referenciar arquivos locais de forma segura
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# --- Variáveis de Configuração ---
KUBE_PROMETHEUS_STACK_VERSION='70.0.0'
RELEASE_NAME='prometheus'
NAMESPACE='monitoring'
VALUES_FILE="$DIR/prometheus-values.yaml"

# --- Cores para o output ---
GREEN='\033[0;32m'
NO_COLOR='\033[0m'

# --- Funções ---

# Função para verificar se as dependências (kubectl, helm) estão instaladas
check_deps() {
  printf "\n%bVerificando dependências...%b\n" "$GREEN" "$NO_COLOR"
  command -v kubectl >/dev/null 2>&1 || { echo "kubectl não encontrado. Abortando."; exit 1; }
  command -v helm >/dev/null 2>&1 || { echo "helm não encontrado. Abortando."; exit 1; }
}

# Função principal para instalar ou atualizar a stack do Prometheus
install_prometheus_stack() {
  printf "\n%bInstalando/Atualizando a stack kube-prometheus-stack...%b\n" "$GREEN" "$NO_COLOR"

  # Adiciona e atualiza o repositório do Helm
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm repo update

  # Executa o comando de instalação/upgrade
  helm upgrade "$RELEASE_NAME" prometheus-community/kube-prometheus-stack \
    --install \
    --version "$KUBE_PROMETHEUS_STACK_VERSION" \
    --namespace "$NAMESPACE" \
    --create-namespace \
    --wait \
    -f "$VALUES_FILE"
}

# --- Execução Principal ---

main() {
  check_deps
  install_prometheus_stack

  printf "\n%b🎉 Instalação concluída com sucesso!%b\n\n" "$GREEN" "$NO_COLOR"
  printf "Para acessar os serviços, configure um Ingress ou use 'kubectl port-forward'.\n"
  printf "Ex: kubectl port-forward -n %s svc/%s-grafana 3000:80\n" "$NAMESPACE" "$RELEASE_NAME"
}

main
