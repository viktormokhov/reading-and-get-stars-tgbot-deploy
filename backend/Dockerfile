FROM python:3.12-bullseye

RUN apt-get update && apt-get install -y \
    iputils-ping vim nano curl dnsutils net-tools less procps openssh-server \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

RUN pip install poetry

COPY pyproject.toml poetry.lock README.md ./

COPY src/* ./

COPY entrypoint.sh /entrypoint.sh

RUN poetry config virtualenvs.create false \
    && poetry install --no-interaction --no-ansi --only main

RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
