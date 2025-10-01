FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

COPY requirements.txt ./
RUN apt-get update \
    && apt-get install -y --no-install-recommends git docker-cli ca-certificates awscli postgresql-client curl \
    && rm -rf /var/lib/apt/lists/* \
    && pip install --no-cache-dir -r requirements.txt \
    && curl -sL https://cli-dl.scalingo.com/build/1.40.0/linux-amd64 -o /tmp/scalingo-install.sh \
    && bash /tmp/scalingo-install.sh --install-dir /usr/local/bin --yes \
    && rm -f /tmp/scalingo-install.sh

COPY app ./app

ENV SCRIPTS_ROOT=/workspace/scripts

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
