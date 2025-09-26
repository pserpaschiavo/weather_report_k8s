# Projeto Weather Pipeline: Pipeline de Dados Meteorológicos Cloud-Native

![Versão](https://img.shields.io/badge/version-1.0.0-blue)
![Status](https://img.shields.io/badge/status-em%20desenvolvimento-yellow)
![Licença](https://img.shields.io/badge/license-MIT-green)

Este repositório contém um projeto de simulação "quasi-real" de um pipeline de dados, demonstrando práticas modernas de DevOps e engenharia de dados em um ambiente Cloud-Native.

O objetivo é coletar dados de previsão do tempo de múltiplas APIs, processá-los, armazená-los em um banco de dados e visualizá-los em dashboards analíticos. Todo o processo é automatizado e orquestrado dentro de um cluster Kubernetes local.

---

## Arquitetura do Sistema

O fluxo de dados segue a arquitetura desacoplada e baseada em microsserviços, ideal para ambientes distribuídos:

![Arquitetura do Projeto](https://i.imgur.com/8YhGZlK.png)

1.  **Orquestração (AWX):** Um Job agendado no AWX inicia o processo.
2.  **Coleta (Ansible):** O AWX executa um playbook Ansible que chama as APIs de previsão do tempo (OpenWeatherMap, WeatherAPI, etc.).
3.  **Ingestão (API Python):** O Ansible envia os dados coletados para um microsserviço de ingestão (Python/Flask) que normaliza e valida os dados.
4.  **Armazenamento (MySQL):** O microsserviço insere os dados tratados em uma instância do MySQL.
5.  **Visualização (Grafana):** O Grafana se conecta ao MySQL como fonte de dados e exibe as informações em dashboards interativos.

Toda a infraestrutura (MySQL, API, AWX, Grafana) é executada como contêineres dentro de um cluster Kubernetes.

---

## 🛠️ Stack de Tecnologia

* **Cluster:** [Kind (Kubernetes in Docker)](https://kind.sigs.k8s.io/)
* **Rede do Cluster (CNI):** [Calico](https://www.tigera.io/project-calico/)
* **Gateway de Entrada:** [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
* **Banco de Dados:** [MySQL](https://www.mysql.com/)
* **API de Ingestão:** [Python 3](https://www.python.org/) + [Flask](https://flask.palletsprojects.com/)
* **Automação/Orquestração:** [Ansible](https://www.ansible.com/) + [AWX](https://github.com/ansible/awx)
* **Visualização:** [Grafana](https://grafana.com/)
* **Infraestrutura como Código (IaC):** Manifestos Kubernetes (YAML)

---

## 🚀 Como Executar o Projeto

### Pré-requisitos

Antes de começar, garanta que você tenha as seguintes ferramentas instaladas:
* [Docker](https://www.docker.com/products/docker-desktop/)
* [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* Chaves de API para os serviços de meteorologia (ver `Fase 0` do [ROADMAP.md](ROADMAP.md)).

### Passos para a Instalação

1.  **Clonar o Repositório:**
    ```bash
    git clone [URL_DO_SEU_REPOSITORIO]
    cd [NOME_DO_SEU_REPOSITORIO]
    ```

2.  **Criar o Cluster Kubernetes:**
    O arquivo de configuração `kind/kind-config.yaml` já está preparado para expor as portas do Ingress.
    ```bash
    kind create cluster --config kind/kind-config.yaml
    ```

3.  **Instalar Componentes de Rede:**
    Aplique os manifestos do Calico e do NGINX Ingress Controller.
    ```bash
    # Instalar Calico CNI
    kubectl apply -f [https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml](https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml)

    # Instalar NGINX Ingress Controller
    kubectl apply -f [https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml](https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml)
    ```

4.  **Implantar as Aplicações:**
    Aplique os manifestos Kubernetes na ordem correta para subir a stack de aplicação (Banco de Dados, API, Grafana, etc.).
    ```bash
    # (Exemplo) A ordem pode ser importante devido às dependências
    kubectl apply -f k8s/mysql/
    kubectl apply -f k8s/ingest-api/
    kubectl apply -f k8s/grafana/
    kubectl apply -f k8s/awx/
    ```

5.  **Configurar o AWX:**
    * Acesse a interface do AWX (instruções a serem adicionadas).
    * Crie as **Credenciais** para armazenar de forma segura as chaves das APIs de tempo.
    * Crie o **Projeto** apontando para este repositório Git.
    * Crie o **Template de Job** para executar o playbook `ansible/coleta_dados.yml`.

6.  **Visualizar os Dados:**
    * Acesse o Grafana (instruções a serem adicionadas).
    * Configure a fonte de dados do MySQL.
    * Importe ou crie os dashboards para visualizar os dados meteorológicos.

---
```
## 📂 Estrutura do Projeto

├── ansible/                # Contém os playbooks do Ansible
│   └── coleta_dados.yml
├── ingest-api/             # Código-fonte e Dockerfile do microsserviço de ingestão
│   ├── app.py
│   ├── requirements.txt
│   └── Dockerfile
├── k8s/                    # Manifestos Kubernetes (YAML)
│   ├── mysql/
│   ├── ingest-api/
│   ├── grafana/
│   └── awx/
├── kind/                   # Configuração do cluster Kind
│   └── kind-config.yaml
├── ROADMAP.md              # Plano de desenvolvimento do projeto
└── README.md               # Este arquivo
```
---

## 👤 Autor

**Phil**

* **LinkedIn:** `[SEU_LINKEDIN]`
* **GitHub:** `[SEU_GITHUB]`
