FROM python:3.12-slim-bullseye

# Установка только необходимых пакетов
# Разделение на два слоя: инструменты разработки и SSH-сервер
# Добавлена переменная окружения для контроля установки инструментов разработки
ARG INSTALL_DEV_TOOLS=false
ARG INSTALL_SSH=false
ENV INSTALL_DEV_TOOLS=${INSTALL_DEV_TOOLS}
ENV INSTALL_SSH=${INSTALL_SSH}

# Установка базовых инструментов и зависимостей для Poetry
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl gcc \
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

# Установка Poetry
RUN pip install --no-cache-dir poetry

# Копирование файлов зависимостей
COPY pyproject.toml poetry.lock README.md ./

# Копирование исходного кода
COPY src/ ./

# Настройка Poetry для установки в системный Python
RUN poetry config virtualenvs.create false

# Установка зависимостей через Poetry
RUN poetry install --only main --no-interaction

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
