# ROADMAP: Pipeline de Dados Meteorológicos com K8s, Ansible e Grafana

Este documento descreve o plano de desenvolvimento para a criação de um pipeline de dados "quasi-real", que coleta dados de APIs de previsão do tempo, os armazena em um banco de dados MySQL e os visualiza no Grafana, tudo orquestrado pelo Ansible/AWX em um cluster Kubernetes local.

**Stack de Tecnologia:**
* **Cluster:** Kind (Kubernetes in Docker)
* **Banco de Dados:** MySQL
* **Aplicação:** Microsserviço de Ingestão (Python/Flask)
* **Orquestração:** Ansible + AWX
* **Visualização:** Grafana
* **Manifestos K8s:** YAMLs nativos (StatefulSet, Deployment, Service, etc.)

---

## Fase 0: Pré-requisitos e Configuração do Ambiente

O objetivo desta fase é preparar sua máquina local com todas as ferramentas necessárias e obter os acessos às APIs.

* [✓] **Milestone 0.1: Instalar Ferramentas de Linha de Comando**
    * [✓] Instalar `docker` - O motor para o Kind.
    * [✓] Instalar `kind` - Para criar o cluster Kubernetes local.
    * [✓] Instalar `kubectl` - Para interagir com o cluster.

* [✓] **Milestone 0.2: Obter Credenciais das APIs**
    * [✓] Criar conta no [OpenWeatherMap](https://openweathermap.org/api) e salvar a Chave de API (API Key).
    * [✓] Criar conta no [WeatherAPI.com](https://www.weatherapi.com/) e salvar a Chave de API.
    * [✓] Criar conta na [HG Brasil Weather](https://hgbrasil.com/status/weather) e salvar a Chave de API.

---

## Fase 1: Fundação - Cluster Kubernetes e Banco de Dados

Nesta fase, construiremos a infraestrutura base: um cluster funcional com um banco de dados persistente rodando.

* [✓] **Milestone 1.1: Criar o Cluster Kubernetes com Kind**
    * [✓] Escrever um arquivo de configuração `kind-config.yaml` para expor a porta do Grafana no host local.
    * [✓] Subir o cluster com o comando: `kind create cluster --config kind-config.yaml`.

* [✓] **Milestone 1.2: Deploy do MySQL com Manifestos Nativos**
    * [✓] **`mysql-pvc.yaml`**: Definir um `PersistentVolumeClaim` para garantir que os dados do MySQL sobrevivam à reinicialização dos Pods.
    * [✓] **`mysql-secrets.yaml`**: Criar um `Secret` para armazenar a senha do root do MySQL de forma segura.
    * [✓] **`mysql-statefulset.yaml`**: Escrever a definição do `StatefulSet` para o MySQL, referenciando o PVC e o Secret criados. Usar a imagem oficial do MySQL.
    * [✓] **`mysql-service.yaml`**: Criar um `Service` do tipo `ClusterIP` chamado `mysql-service` para que outras aplicações dentro do cluster possam se conectar ao banco de dados de forma estável.
    * [✓] Aplicar todos os manifestos com `kubectl apply -f .` e verificar se o Pod do MySQL está `Running`.

---

## Fase 2: Camada de Aplicação e Ingestão

Aqui, vamos preparar e implantar a estrutura do nosso microsserviço que receberá os dados. A lógica interna será implementada na Fase 4.

* [ ] **Milestone 2.1: Estruturar o Microsserviço de Ingestão**
    * [ ] Criar a estrutura de arquivos do projeto Python (ex: `app.py`, `requirements.txt`).
    * [ ] Adicionar as dependências (`Flask`, `mysql-connector-python`) no `requirements.txt`.
    * [ ] Criar o `Dockerfile` para "containerizar" a aplicação.
    * [ ] Fazer o build da imagem Docker localmente: `docker build -t ingest-api:v0.1 .`.
    * [ ] Carregar a imagem para dentro do cluster Kind: `kind load docker-image ingest-api:v0.1`.

* [ ] **Milestone 2.2: Deploy do Microsserviço no Kubernetes**
    * [ ] **`api-deployment.yaml`**: Criar um `Deployment` para gerenciar os Pods da API. A configuração do banco de dados (host, usuário) deve ser passada via variáveis de ambiente, buscando os valores do `Secret` do MySQL.
    * [ ] **`api-service.yaml`**: Criar um `Service` do tipo `ClusterIP` chamado `api-ingestao-service` para expor a API para outros serviços, como o AWX.
    * [ ] Aplicar os manifestos e verificar se os Pods da API estão `Running`.

---

## Fase 3: Automação e Orquestração

O objetivo é instalar e configurar a base do nosso orquestrador, o AWX.

* [ ] **Milestone 3.1: Deploy do AWX no Cluster**
    * [ ] Instalar o AWX Operator no cluster seguindo a documentação oficial.
    * [ ] Criar um manifesto `awx-instance.yaml` para definir e implantar uma instância do AWX.
    * [ ] Aplicar o manifesto e aguardar todos os Pods do AWX ficarem `Running`.
    * [ ] Expor a interface do AWX usando `kubectl port-forward` e fazer o primeiro login.

* [ ] **Milestone 3.2: Estruturar o Projeto Ansible**
    * [ ] Criar um repositório Git para o projeto.
    * [ ] Dentro do repositório, criar o arquivo `coleta_dados.yml` com a estrutura básica do playbook (hosts, nome), mas sem a lógica das tasks.

---

## Fase 4: Implementação da Lógica e Testes de Integração

**Agora sim, vamos escrever o código!** Com toda a infraestrutura de pé, podemos focar na lógica que conecta as peças.

* [ ] **Milestone 4.1: Desenvolver o Código do Microsserviço de Ingestão**
    * [ ] Implementar a lógica em `app.py` (Python/Flask) para:
        * Receber uma requisição POST na rota `/ingest`.
        * Conectar-se ao MySQL usando as variáveis de ambiente.
        * Inserir os dados do JSON recebido em uma tabela.
        * Criar a tabela (`CREATE TABLE IF NOT EXISTS...`) na primeira conexão.
    * [ ] Reconstruir a imagem (`docker build`) e recarregá-la no Kind (`kind load`).

* [ ] **Milestone 4.2: Desenvolver o Playbook Ansible**
    * [ ] Implementar as tasks no `coleta_dados.yml`:
        * Usar o módulo `ansible.builtin.uri` para chamar cada uma das 3 APIs de tempo.
        * Registrar a saída de cada chamada.
        * Normalizar o JSON de resposta de cada API para um formato padrão.
        * Usar o módulo `ansible.builtin.uri` novamente para fazer um POST com o JSON normalizado para o `api-ingestao-service`.

* [ ] **Milestone 4.3: Configurar e Testar o Job no AWX**
    * [ ] No AWX, criar **Credenciais** para armazenar as chaves das APIs de tempo de forma segura.
    * [ ] Criar um **Projeto** que aponta para o seu repositório Git.
    * [ ] Criar um **Template de Job** que usa o seu playbook.
    * [ ] **Executar o Job manualmente** e realizar o primeiro teste de ponta a ponta.
    * [ ] **Verificar**:
        * Logs do Job no AWX.
        * Logs do Pod do microsserviço de ingestão (`kubectl logs ...`).
        * Dados na tabela do MySQL (`kubectl exec -it ... mysql -p ...`).

---

## Fase 5: Visualização e Análise

Com os dados fluindo, é hora de dar vida a eles.

* [ ] **Milestone 5.1: Deploy do Grafana**
    * [ ] **`grafana-pvc.yaml`**: Criar um PVC para persistir os dashboards e configurações do Grafana.
    * [ ] **`grafana-deployment.yaml`**: Criar um `Deployment` para o Grafana.
    * [ ] **`grafana-service.yaml`**: Criar um `Service` do tipo `NodePort` para expor o Grafana e permitir o acesso pelo seu navegador.
    * [ ] Aplicar os manifestos e acessar a interface do Grafana.

* [ ] **Milestone 5.2: Configurar o Grafana**
    * [ ] Adicionar o MySQL (`mysql-service`) como um novo *Data Source*.
    * [ ] Testar a conexão.

* [ ] **Milestone 5.3: Criar Dashboards de Análise**
    * [ ] Criar um novo dashboard.
    * [ ] Adicionar um painel do tipo "Time series".
    * [ ] Escrever queries SQL para buscar os dados de temperatura, umidade, etc., agrupados por fonte (OpenWeatherMap, WeatherAPI, etc.).
    * [ ] Criar painéis comparativos e de análise estatística (média, etc.).

---

## Fase 6: Finalização e Próximos Passos

Ajustes finais para transformar o projeto em um pipeline automatizado e contínuo.

* [ ] **Milestone 6.1: Agendar a Automação no AWX**
    * [ ] Na configuração do Template de Job no AWX, criar um *Schedule* para executar a coleta de dados periodicamente (ex: a cada 30 minutos).

* [ ] **Milestone 6.2: Documentação Final**
    * [ ] Criar um `README.md` no repositório do projeto explicando a arquitetura, como executá-lo e as decisões tomadas.
    * [ ] Garantir que todos os manifestos YAML e códigos estejam versionados no Git.
