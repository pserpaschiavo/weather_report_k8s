---
# CHANGELOG - Projeto Weather Pipeline

Este documento é o diário técnico do projeto, registrando as principais decisões, desafios e soluções implementadas em cada fase da construção do pipeline de dados meteorológicos.

---

## Fase 0: Pré-requisitos e Configuração do Ambiente

**Objetivo:** Estabelecer um ambiente de desenvolvimento local robusto e obter os acessos necessários para as fontes de dados externas.

**Decisões e Ações:**

- **Seleção de Ferramentas:** Foram escolhidas ferramentas padrão da indústria para garantir que o ambiente local espelhasse de perto um cenário de produção: Docker como motor de contêineres, Kind para a criação de um cluster Kubernetes multi-nó local e kubectl para a interação com o cluster.
- **Obtenção de Credenciais:** Foram criadas contas em múltiplos provedores de API de meteorologia (OpenWeatherMap, WeatherAPI, etc.) para garantir a diversidade e resiliência na coleta de dados. As chaves de API foram armazenadas localmente para uso futuro nas configurações de automação.

**Resultado:**
Um ambiente de desenvolvimento totalmente funcional e preparado, com todas as ferramentas e credenciais necessárias para iniciar a construção da infraestrutura.

---

## Fase 1: Fundação - Cluster Kubernetes e Banco de Dados

**Objetivo:** Construir a infraestrutura base do projeto, incluindo o cluster, a rede, o monitoramento e um banco de dados de alta disponibilidade.

### 1. Criação do Cluster e Rede Avançada

- **Desafio:** Garantir que o cluster local fosse o mais "verossímil" possível, suportando rede avançada e gerenciamento de tráfego de entrada.
- **Diagnóstico:** Um cluster Kind padrão não inclui uma CNI (Container Network Interface) avançada nem um Ingress Controller.
- **Solução:**
    - O cluster foi configurado para desabilitar a CNI padrão, permitindo a instalação do Calico, que oferece políticas de rede mais robustas.
    - O manifesto do Kind foi ajustado com `extraPortMappings` nas portas 80 e 443, preparando o terreno para a instalação de um NGINX Ingress Controller. Esta abordagem permite expor serviços através de Ingress, a forma profissional de gerenciar o tráfego em um ambiente Kubernetes.

### 2. Implantação do Banco de Dados com MySQL Operator

- **Desafio:** Implantar um banco de dados MySQL de forma resiliente e de alta disponibilidade, seguindo as melhores práticas "Cloud-Native".
- **Diagnóstico:** A implantação manual de um banco de dados stateful com manifestos StatefulSet é complexa e propensa a erros. A utilização de um Operator abstrai essa complexidade.
- **Solução:**
    - Foi adotado o MySQL Operator for Kubernetes. Um único manifesto declarativo (`kind: InnoDBCluster`) foi usado para instruir o Operator a criar um cluster completo com 3 nós de banco de dados e um MySQL Router para gerenciar as conexões, garantindo alta disponibilidade e failover automático.

### 3. Depuração da Conexão Inicial com o Banco de Dados

- **Desafio:** Após a implantação, a conexão inicial com o banco de dados falhava com erros de Unknown host e, posteriormente, Access denied.
- **Diagnóstico:** A investigação, utilizando ferramentas como `kubectl get service` e `kubectl get secret`, revelou duas causas:
    - O nome do Service para conexão (`mysql-cluster`) era diferente do nome do recurso InnoDBCluster (`mycluster`).
    - Os pods do MySQL haviam inicializado com uma senha incorreta ou desatualizada que estava no Secret no momento da criação.
- **Solução:**
    - A conexão foi corrigida usando o nome de Service correto.
    - O problema de Access denied foi resolvido forçando uma reinicialização controlada (rolling restart) dos pods do StatefulSet do MySQL, o que os obrigou a reler a senha correta do Secret.

**Resultado:**
Uma infraestrutura Kubernetes completa e robusta, com um banco de dados de alta disponibilidade pronto e validado para receber os dados da aplicação.

---

## Fase 2: Implantação do Microsserviço de Ingestão

Este documento registra as principais decisões arquiteturais, os desafios de depuração em profundidade e as soluções implementadas durante a Fase 2 do projeto. Esta fase culminou na implantação bem-sucedida de um microsserviço ingest-api robusto, marcando um passo crucial na construção do nosso pipeline de dados.

### Arquitetura Final da Aplicação

A solução evoluiu de um simples script para uma arquitetura madura e alinhada com as melhores práticas "Cloud-Native", utilizando o padrão Init Container no Kubernetes. Esta abordagem desacopla a inicialização da execução, um pilar para aplicações resilientes em ambientes orquestrados.

- **Init Container (db-initializer):**
    - **Responsabilidade:** Atuar como um "preparador de terreno" que executa o script `init_db.py` uma única vez, antes que qualquer outro contêiner no Pod seja iniciado.
    - **Ação:** Conectar-se ao MySQL para garantir que o banco de dados e a tabela `leituras` existam. Ele efetivamente age como uma barreira, impedindo que a aplicação principal inicie em um estado inconsistente.
    - **Benefício:** Elimina "race conditions" (condições de corrida), onde a aplicação poderia tentar se conectar a uma tabela que ainda não existe. Isso torna o sistema significativamente mais resiliente a reinicializações e implantações iniciais, simplificando a lógica do contêiner principal.

- **App Container (api):**
    - **Responsabilidade:** Executar o script principal `app.py`, focando exclusivamente na lógica de negócio.
    - **Ação:** Iniciar o servidor Flask e expor os endpoints `/ingest` (para receber dados) e `/healthcheck` (para verificação de saúde, permitindo que o Kubernetes monitore a aplicação).
    - **Benefício:** O contêiner da aplicação agora parte do pressuposto de que seu ambiente está pronto. Ele pode ser reiniciado de forma independente pelo Kubernetes (por exemplo, se falhar em uma verificação de saúde) sem acionar novamente a lógica de inicialização do banco, tornando as recuperações mais rápidas e limpas.

---

## Lições Aprendidas e Desafios Superados

A jornada de depuração nesta fase foi fundamental para solidificar conceitos práticos de DevOps e engenharia de software em um ambiente Kubernetes.

### 1. Conexão com o MySQL Router

- **Desafio:** A aplicação falhava na conexão com o banco, apesar de os testes de rede básicos (`telnet`) na porta 3306 funcionarem, criando um cenário aparentemente contraditório.
- **Diagnóstico:** A investigação profunda revelou que o ponto de entrada para um cluster de alta disponibilidade não é um nó de banco de dados individual (na porta 3306), mas sim o MySQL Router. Este componente atua como um proxy inteligente que abstrai a topologia do cluster, ouvindo em portas dedicadas (como a porta 6446 para leitura/escrita) e direcionando o tráfego para o nó primário correto, mesmo em caso de failover.
- **Solução:** A correção foi arquitetural: adicionamos a variável de ambiente `DB_PORT` ao ConfigMap com o valor 6446 e atualizamos o código Python para utilizar esta porta, garantindo que a aplicação sempre se comunique através do ponto de entrada correto e resiliente.

### 2. Tipagem de Variáveis de Ambiente

- **Desafio:** Mesmo após a correção da porta, a conexão continuava a falhar, indicando um problema mais sutil.
- **Diagnóstico:** As variáveis de ambiente, por sua natureza, são sempre lidas como do tipo string. Nosso código Python passava a string "6446" para a biblioteca `mysql-connector-python`, que, em vez de gerar um erro explícito, provavelmente ignorava o parâmetro malformado e voltava a usar a porta padrão 3306 silenciosamente.
- **Solução:** Implementamos a conversão explícita de tipos no código: `port=int(os.environ.get("DB_PORT"))`. Esta lição reforça a importância da validação e da sanitização de dados na "borda" da aplicação, onde as configurações externas são injetadas.

### 3. Conflito de Dependências (Flask vs. Werkzeug)

- **Desafio:** Após a implementação do Init Container, a aplicação principal (`app.py`) passou a falhar na inicialização com um ImportError, indicando que uma função interna (`url_quote`) havia desaparecido de sua dependência, o Werkzeug.
- **Diagnóstico:** Este é um caso clássico de "dependency hell". Uma atualização recente da biblioteca Werkzeug para uma nova versão principal (v3.0) introduziu "breaking changes", removendo funções que a nossa versão do Flask==2.2.2 ainda esperava que existissem.
- **Solução:** A solução foi aplicar uma das práticas mais importantes para a criação de builds consistentes: "pinar" (fixar) a versão do Werkzeug no arquivo `requirements.txt` para uma versão sabidamente compatível (`Werkzeug==2.2.3`). Isso garante que o ambiente seja 100% reproduzível, independentemente de quando ou onde a imagem Docker seja construída.

---

## Resultado

A Fase 2 foi concluída com um microsserviço ingest-api (versão v1.1) que não é apenas funcional, mas também resiliente, observável e construído sobre uma arquitetura robusta. Ele agora serve como uma base sólida e confiável para as próximas fases de automação e visualização de dados. A jornada de depuração, embora desafiadora, foi imensamente valiosa, solidificando conceitos cruciais de rede no Kubernetes, gerenciamento de dependências e a importância de práticas de codificação defensiva em aplicações Cloud-Native.
---
