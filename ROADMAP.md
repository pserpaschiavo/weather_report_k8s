---
# ROADMAP: Pipeline de Dados Meteorológicos com K8s, Ansible e Grafana

Este documento descreve o plano de desenvolvimento para a criação de um pipeline de dados "quasi-real", que coleta dados de APIs de previsão do tempo, os armazena em um banco de dados MySQL e os visualiza no Grafana, tudo orquestrado pelo Ansible/AWX em um cluster Kubernetes local.

## Stack de Tecnologia

- **Cluster:** Kind (Kubernetes in Docker)  
    Para criar um ambiente Kubernetes local, multi-nó, que simula de forma fiel um cluster de produção.
- **Banco de Dados:** MySQL (via MySQL Operator)  
    Para um armazenamento de dados robusto e de alta disponibilidade, gerenciado de forma declarativa.
- **Aplicação:** Microsserviço de Ingestão (Python/Flask)  
    O coração do nosso pipeline, responsável por receber, validar e persistir os dados.
- **Orquestração:** Ansible + AWX  
    Para automatizar a coleta de dados de fontes externas de forma agendada e centralizada.
- **Visualização:** Grafana  
    Para transformar os dados brutos armazenados no banco em dashboards e gráficos informativos.
- **Monitoramento:** Prometheus Operator  
    Para garantir a observabilidade do nosso cluster e aplicações.
- **Manifestos K8s:** YAMLs nativos (StatefulSet, Deployment, Service, etc.)  
    Para praticar e dominar os fundamentos da configuração de aplicações no Kubernetes.

---

## ✅ Fase 0: Pré-requisitos e Configuração do Ambiente

**Status:** (✓) Concluída

**Entregáveis:**  
Ambiente de desenvolvimento local totalmente configurado com as ferramentas de linha de comando (docker, kind, kubectl) essenciais para a orquestração de contêineres, e as chaves de API para as fontes de dados externas devidamente obtidas e armazenadas de forma segura.

---

## ✅ Fase 1: Fundação - Cluster Kubernetes e Banco de Dados

**Status:** (✓) Concluída

**Entregáveis:**  
Infraestrutura Kubernetes robusta e funcional, com rede avançada via Calico CNI, gerenciamento de tráfego de entrada com NGINX Ingress e observabilidade inicial garantida pelo Prometheus Operator. O pilar desta fase é o cluster MySQL de alta disponibilidade, implantado via MySQL Operator, com sua operacionalidade validada através de testes de conexão direta.

---

## ✅ Fase 2: Camada de Aplicação e Ingestão

**Status:** (✓) Concluída

**Entregáveis:**  
Microsserviço ingest-api resiliente e bem-arquitetado, desenvolvido em Python/Flask e containerizado. A implantação utiliza Init Container para garantir a inicialização correta do banco de dados antes da aplicação principal iniciar. O sucesso da fase foi validado com testes de inserção de dados de ponta a ponta.

---

## ➡️ Fase 3: Automação e Orquestração

**Status:** (A Fazer) - Próximo Passo

**Objetivo:**  
Implantar a ferramenta de orquestração (AWX) e criar a estrutura do projeto de automação (Ansible) que alimentará nossa API.

### Milestone 3.1: Deploy do AWX no Cluster via Operator

- [ ] Instalar o AWX Operator no cluster
- [ ] Criar um manifesto `awx-instance.yaml`
- [ ] Configurar um recurso Ingress para expor a interface web do AWX

### Milestone 3.2: Estruturar o Projeto Ansible

- [ ] Criar um repositório Git dedicado
- [ ] Desenvolver a estrutura inicial do playbook `coleta_dados.yml`

---

## ⏹️ Fase 4: Implementação da Lógica e Testes de Integração

**Status:** (Aguardando)

**Objetivo:**  
Dar vida à automação, escrevendo as tasks no playbook Ansible para consumir as APIs de meteorologia, extrair e formatar os dados JSON relevantes, e enviar esses dados via POST para o endpoint `/ingest` da API.

---

## ⏹️ Fase 5: Visualização e Análise

**Status:** (Aguardando)

**Objetivo:**  
Transformar dados brutos em informação visual e acionável. Após a implantação do Grafana, configurar o MySQL como Data Source e construir dashboards com queries SQL para plotar gráficos de temperatura, umidade e pressão ao longo do tempo.

---

## ⏹️ Fase 6: Finalização e Próximos Passos

**Status:** (Aguardando)

**Objetivo:**  
Configurar um Schedule no AWX para que o job de coleta de dados seja executado em intervalos regulares (ex: a cada 30 minutos). Refinar a documentação (README.md) para refletir a arquitetura final e fornecer instruções claras de execução.
---
