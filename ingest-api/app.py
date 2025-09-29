import os
import mysql.connector
import logging

from flask import Flask, request, jsonify

logging.basicConfig(level=logging.INFO)
app = Flask(__name__)

def get_db_connection():
    try:
        db_port = int(os.environ.get("DB_PORT", "3306"))

        conn = mysql.connector.connect(
            host=os.environ.get("DB_HOST"),
            user=os.environ.get("DB_USER"),
            password=os.environ.get("DB_PASSWORD"),
            database=os.environ.get("DB_NAME"),
            port=db_port
        )
        logging.info("Conexão com o banco de dados bem-sucedida!")
        return conn
    except mysql.connector.Error as err:
        logging.error(f"Erro ao conectar ao banco de dados: {err}")
        return None


@app.route('/healthcheck', methods=['GET'])
def healthcheck():
    conn = get_db_connection()
    if conn is None:
        return jsonify({"status": "erro", "message": "Não foi possível conectar ao banco de dados"}), 500
    
    conn.close()
    return jsonify({"status": "ok", "message": "Conexão com o banco de dados estabelecida com sucesso"}), 200


@app.route('/ingest', methods=['POST'])
def ingest_data():
    data = request.json
    logging.info(f"Recebido dado para ingestão: {data}")

    required_keys = ['source', 'temperature', 'humidity', 'pressure']
    if not all(key in data for key in required_keys):
        return jsonify({"error": "JSON incompleto. Chaves obrigatórias ausentes."}), 400

    conn = get_db_connection()
    if conn is None:
        return jsonify({"error": "Falha na conexão com o banco de dados."}), 500

    try:
        cursor = conn.cursor()
        query = ("INSERT INTO leituras (fonte, temperatura, umidade, pressao) "
                 "VALUES (%s, %s, %s, %s)")
        values = (data['source'], data['temperature'], data['humidity'], data['pressure'])
        cursor.execute(query, values)
        conn.commit()
        cursor.close()
        logging.info("Dados inseridos com sucesso no banco de dados.")
        return jsonify({"status": "sucesso"}), 201
    except mysql.connector.Error as err:
        logging.error(f"Erro ao inserir dados no banco de dados: {err}")
        return jsonify({"error": f"Erro ao inserir dados no banco de dados: {err}"}), 500
    finally:
        if conn and conn.is_connected():
            conn.close()
            logging.info("Conexão com o banco de dados fechada.")

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

