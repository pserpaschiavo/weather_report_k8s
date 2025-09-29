# Dockerfile para a aplicação ingest-api

# --- ESTÁGIO 1: A "Cozinha de Preparo" (Builder) ---
# Começamos com uma imagem base do Python 3.9 "slim", que é leve e segura.
# Damos um nome a este estágio, "builder", para podermos nos referir a ele mais tarde.
FROM python:3.9-slim AS builder

# Definimos o diretório de trabalho dentro do contêiner.
WORKDIR /app

# Criamos um ambiente virtual. Isso espelha a boa prática que usamos localmente
# e mantém as dependências isoladas.
RUN python -m venv /opt/venv

# Adicionamos o diretório 'bin' do nosso venv ao PATH do sistema.
ENV PATH="/opt/venv/bin:$PATH"

# Copiamos apenas o arquivo de requisitos para dentro do contêiner.
# Esta é uma otimização de cache do Docker: se o requirements.txt não mudar,
# esta camada não precisa ser reconstruída.
COPY requirements.txt .

# Instalamos as dependências usando o pip do nosso ambiente virtual.
RUN pip install --no-cache-dir -r requirements.txt


# --- ESTÁGIO 2: A "Cozinha de Finalização" (Final) ---
# Começamos de novo com a mesma imagem base leve.
# Esta será a nossa imagem final, contendo apenas o necessário para rodar.
FROM python:3.9-slim

# Definimos o mesmo diretório de trabalho.
WORKDIR /app

# A MÁGICA ACONTECE AQUI:
# Copiamos o ambiente virtual JÁ PRONTO com as dependências instaladas
# do estágio "builder" para a nossa nova imagem.
COPY --from=builder /opt/venv /opt/venv

# Copiamos os scripts da nossa aplicação para o diretório de trabalho.
# Ambos os scripts precisam estar na imagem, pois ela será usada tanto
# pelo Init Container quanto pelo contêiner principal.
COPY app.py init_db.py ./

# Novamente, garantimos que o PATH aponte para o nosso venv.
ENV PATH="/opt/venv/bin:$PATH"

# Esta variável de ambiente é uma boa prática para garantir que os logs (prints)
# do Python sejam enviados diretamente para o console, sem buffer,
# facilitando a depuração com "kubectl logs".
ENV PYTHONUNBUFFERED=1

# Informamos ao Docker que o nosso contêiner vai "ouvir" na porta 5000.
# Isso não abre a porta, apenas a documenta para referência.
EXPOSE 5000

# O comando final que será executado quando o contêiner iniciar.
# Por padrão, ele inicia a aplicação principal. O nosso Init Container
# no manifesto do Deployment irá sobrescrever este comando para rodar "init_db.py".
CMD ["python", "app.py"]


