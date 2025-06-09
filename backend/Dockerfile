FROM python:3.12-slim-bullseye AS builder

# Установка только необходимых зависимостей для сборки
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Установка Poetry
RUN pip install --no-cache-dir poetry

# Копирование только файлов зависимостей
COPY pyproject.toml poetry.lock README.md ./

# Экспорт зависимостей в requirements.txt для более эффективной установки
RUN poetry export -f requirements.txt --output requirements.txt --only main

# Финальный образ
FROM python:3.12-slim-bullseye

# Установка только необходимых пакетов
# Разделение на два слоя: инструменты разработки и SSH-сервер
# Добавлена переменная окружения для контроля установки инструментов разработки
ARG INSTALL_DEV_TOOLS=false
ARG INSTALL_SSH=false
ENV INSTALL_DEV_TOOLS=${INSTALL_DEV_TOOLS}
ENV INSTALL_SSH=${INSTALL_SSH}

# Установка базовых инструментов
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Условная установка инструментов разработки
RUN if [ "$INSTALL_DEV_TOOLS" = "true" ]; then \
    apt-get update && apt-get install -y --no-install-recommends \
    iputils-ping vim nano dnsutils net-tools less procps \
    && rm -rf /var/lib/apt/lists/*; \
    fi

# Условная установка SSH-сервера
RUN if [ "$INSTALL_SSH" = "true" ]; then \
    apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    && rm -rf /var/lib/apt/lists/*; \
    fi

WORKDIR /src

# Копирование requirements.txt из builder
COPY --from=builder /build/requirements.txt .

# Установка зависимостей
RUN pip install --no-cache-dir -r requirements.txt

# Копирование исходного кода
COPY src/ ./

# Копирование и настройка entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Переменная окружения для режима разработки
ENV DEV_MODE=false

# Порт для API
EXPOSE 8000

# Порт для SSH (если включен)
EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
