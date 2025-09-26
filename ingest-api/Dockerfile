FROM python:3.9-slim

WORKDIR /app

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .

RUN pip install --no-cache-dir --upgrade pip \
    && pip uninstall -y flask werkzeug || true \
    && pip install --no-cache-dir -r requirements.txt \
    && pip list

FROM python:3.9-slim
WORKDIR /app

COPY --from=0 /opt/venv /opt/venv

COPY app.py init_db.py ./

ENV PATH="/opt/venv/bin:$PATH"
ENV PYTHONUNBUFFERED=1

EXPOSE 5000

# Inicializa o banco de dados e depois inicia a aplicação
CMD ["sh", "-c", "python init_db.py && python app.py"]

