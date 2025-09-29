import os
import mysql.connector
import logging

logging.basicConfig(level=logging.INFO)

def init_database():
    try:
        # Configuração para conexão ao MySQL sem especificar o banco de dados
        db_config = {
            'host': os.environ.get("DB_HOST", "localhost"),
            'user': os.environ.get("DB_USER", "root"),
            'password': os.environ.get("DB_PASSWORD", ""),
            'port': int(os.environ.get("DB_PORT", "3306")),
        }
        
        # Log da tentativa de conexão (sem expor a senha)
        safe_config = {k: v for k, v in db_config.items() if k != 'password'}
        logging.info(f"Tentando conectar ao servidor MySQL com configuração: {safe_config}")
        
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor()
        
        # Verificar se o banco de dados existe, se não, criar
        db_name = os.environ.get("DB_NAME", "mysql")
        cursor.execute(f"CREATE DATABASE IF NOT EXISTS {db_name}")
        logging.info(f"Banco de dados '{db_name}' verificado/criado.")
        
        # Selecionar o banco de dados
        cursor.execute(f"USE {db_name}")
        
        # Criar tabela se não existir
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS leituras (
            id INT AUTO_INCREMENT PRIMARY KEY,
            fonte VARCHAR(100) NOT NULL,
            temperatura FLOAT NOT NULL,
            umidade FLOAT NOT NULL,
            pressao FLOAT NOT NULL,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
        """)
        logging.info("Tabela 'leituras' verificada/criada.")
        
        conn.commit()
        cursor.close()
        conn.close()
        
        logging.info("Inicialização do banco de dados concluída com sucesso!")
        return True
    except mysql.connector.Error as err:
        logging.error(f"Erro ao inicializar banco de dados: {err}")
        return False

if __name__ == "__main__":
    init_database()
