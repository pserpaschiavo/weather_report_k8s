#!/bin/bash

# Verificar se as variáveis de ambiente já foram definidas
if [ -z "$DB_HOST" ]; then
  echo "Configurando variáveis de ambiente para desenvolvimento local..."
  export DB_HOST=localhost
  export DB_USER=root
  export DB_PASSWORD=""
  export DB_NAME=mysql
  export DB_PORT=3306
fi

# Instalar dependências
pip install -r requirements.txt

# Inicializar o banco de dados
python init_db.py

# Iniciar a aplicação
python app.py
