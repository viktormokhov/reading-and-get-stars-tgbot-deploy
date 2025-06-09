# Telegram WebApp для чтения

Этот проект представляет собой Telegram WepApp для чтения с использованием микросервисной архитектуры на базе Docker.

## Компоненты проекта

- **Backend**: API-сервер на Python
- **Frontend**: Telegram-бот на Node.js
- **PostgreSQL**: Основная база данных
- **MongoDB**: База данных для хранения неструктурированных данных
- **Redis**: Кэширование и очереди задач
- **MinIO**: Хранилище объектов (S3-совместимое)
- **Nginx**: Обратный прокси-сервер с SSL

## Требования

- Docker и Docker Compose
- Доступ к интернету для скачивания образов
- Открытые порты для Telegram API
- OpenSSL для генерации сертификатов

## Установка и настройка

### 1. Клонирование репозитория

```bash
git clone <url-репозитория>
cd reading-and-get-stars-tgbot-deploy
```

### 2. Создание файла .env

В репозитории есть файл `.env.example` с примерами всех необходимых переменных окружения. Скопируйте его в файл `.env` и замените значения на свои:

```bash
cp .env.example .env
```

Затем отредактируйте файл `.env`, указав свои значения для следующих переменных:

```
# PostgreSQL
POSTGRES_USER=username
POSTGRES_PASSWORD=password
POSTGRES_DB=tgbot

# MongoDB
MONGO_INITDB_ROOT_USERNAME=username
MONGO_INITDB_ROOT_PASSWORD=password

# Redis
REDIS_PASSWORD=password

# MinIO
MINIO_ROOT_USER=username
MINIO_ROOT_PASSWORD=password

# Backend
BACKEND_API_KEY=your_api_key
# Режим разработки для бэкенда (true/false)
BACKEND_DEV_MODE=false
# Установка инструментов разработки (true/false)
BACKEND_DEV_TOOLS=false
# Установка SSH-сервера (true/false)
BACKEND_INSTALL_SSH=false
# Запускать ли приложение в режиме разработки
BACKEND_RUN_APP_IN_DEV=false
# Пароль для SSH (если включен)
BACKEND_SSH_PASSWORD=strong_password
# Путь к исходному коду для монтирования (для разработки)
# BACKEND_MOUNT_SRC=./backend/src
# Режим монтирования (ro - только чтение, rw - чтение и запись)
# BACKEND_MOUNT_MODE=ro
# Время ожидания перед первой проверкой здоровья
BACKEND_HEALTHCHECK_START_PERIOD=30s

# Frontend
# Режим разработки для фронтенда (true/false)
NODE_DEV_MODE=false
# Установка инструментов разработки (true/false)
FRONTEND_DEV_TOOLS=false
# Монтирование исходного кода (для разработки)
# FRONTEND_MOUNT_SRC=./frontend/src
# FRONTEND_MOUNT_PUBLIC=./frontend/public
# FRONTEND_MOUNT_MODE=ro
# Настройка доступа к порту (0.0.0.0 для прямого доступа, 127.0.0.1 для локального)
FRONTEND_EXPOSE_PORT=127.0.0.1
# Настройки healthcheck
FRONTEND_HEALTHCHECK_INTERVAL=30s
FRONTEND_HEALTHCHECK_TIMEOUT=10s
FRONTEND_HEALTHCHECK_RETRIES=3
FRONTEND_HEALTHCHECK_START_PERIOD=30s

# Telegram Bot
TG_BOT_TOKEN=your_telegram_bot_token
TG_ADMIN_ID=your_telegram_id

# AI Services (если используются)
OPENAI_API_KEY=your_openai_api_key
XAI_API_KEY=your_xai_api_key
HUGGINGFACE_API_KEY=your_huggingface_api_key
```

### 3. Генерация сертификатов

#### Сертификаты для MinIO

Запустите скрипт для генерации сертификатов MinIO:

```bash
cd minio_data/certs
chmod +x create_certs.sh
./create_certs.sh
cd ../..
```

#### Сертификаты для Nginx

Для Nginx требуются сертификаты SSL. Вы можете использовать:

1. **Скрипт для генерации самоподписанных сертификатов** (рекомендуется для тестирования):

```bash
cd nginx/certs
chmod +x create_certs.sh
./create_certs.sh
cd ../..
```

2. **Ручная генерация самоподписанных сертификатов**:

```bash
mkdir -p nginx/certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/certs/privkey.pem \
  -out nginx/certs/fullchain.pem \
  -subj "/C=RU/ST=Region/L=City/O=Organization/CN=read-q.cloudns.ch"
```

3. **Let's Encrypt** (для продакшена):
   - Используйте certbot или другой клиент ACME для получения сертификатов
   - Поместите полученные сертификаты в папку `nginx/certs/`

### 4. Запуск проекта

```bash
docker-compose up -d
```

Для просмотра логов:

```bash
docker-compose logs -f
```

## Проверка работоспособности

- Бэкенд API: https://read-q.cloudns.ch:8443/api/docs
- MinIO консоль: http://localhost:9001
- Telegram-бот: Найдите вашего бота в Telegram и отправьте команду `/start`

## Разработка

Для разработки и отладки можно использовать PyCharm Professional с Docker. Инструкции по настройке SSH-подключения к Docker находятся в файле `docker_ssh_setup.md`.

### Режим разработки

Проект поддерживает специальный режим разработки, который можно активировать через переменные окружения:

#### Для бэкенда:

1. Установите в `.env` следующие переменные:
   ```
   BACKEND_DEV_MODE=true
   BACKEND_DEV_TOOLS=true
   BACKEND_INSTALL_SSH=true
   BACKEND_RUN_APP_IN_DEV=true
   BACKEND_SSH_PASSWORD=your_password
   BACKEND_MOUNT_SRC=./backend/src
   BACKEND_MOUNT_MODE=rw
   ```

2. Перезапустите контейнеры:
   ```bash
   docker-compose up -d backend
   ```

3. Подключитесь по SSH к бэкенду:
   ```bash
   ssh root@localhost -p 7721
   ```

#### Для фронтенда:

1. Установите в `.env` следующие переменные:
   ```
   # Основные настройки разработки
   NODE_DEV_MODE=true
   FRONTEND_DEV_TOOLS=true

   # Монтирование исходного кода (для live-редактирования)
   FRONTEND_MOUNT_SRC=./frontend/src
   FRONTEND_MOUNT_PUBLIC=./frontend/public
   FRONTEND_MOUNT_MODE=rw

   # Настройки для прямого доступа к порту (без Nginx)
   FRONTEND_EXPOSE_PORT=0.0.0.0

   # Настройки healthcheck
   FRONTEND_HEALTHCHECK_INTERVAL=10s
   FRONTEND_HEALTHCHECK_TIMEOUT=5s
   FRONTEND_HEALTHCHECK_RETRIES=5
   FRONTEND_HEALTHCHECK_START_PERIOD=60s
   ```

2. Перезапустите контейнеры:
   ```bash
   docker-compose up -d frontend
   ```

3. Доступ к фронтенду в режиме разработки:
   - Веб-интерфейс: http://localhost:3000
   - API: http://localhost:3000/api/
   - Изменения в коде автоматически применяются благодаря hot-reload

### Оптимизации

В проекте реализованы следующие оптимизации:

#### Общие оптимизации:

1. **Многоэтапная сборка (Multi-stage build)**:
   - Уменьшение размера итоговых образов
   - Разделение этапов сборки и выполнения
   - Оптимизация слоев Docker-образов

2. **Условная установка компонентов**:
   - Инструменты разработки устанавливаются только при необходимости
   - Разделение production и development зависимостей

3. **Улучшенная безопасность**:
   - Запуск сервисов от непривилегированных пользователей
   - Конфигурируемые пароли через переменные окружения
   - Отключение небезопасных настроек в продакшен-режиме

4. **Гибкая конфигурация**:
   - Все параметры настраиваются через переменные окружения
   - Значения по умолчанию для всех параметров
   - Возможность монтирования исходного кода для разработки

#### Оптимизации бэкенда:

1. **Оптимизация Python-окружения**:
   - Использование slim-образа для уменьшения размера
   - Эффективная установка зависимостей через Poetry
   - Условная установка SSH-сервера только в режиме разработки

2. **Улучшенное управление процессами**:
   - Автоматический перезапуск приложения при изменении кода
   - Настраиваемые параметры healthcheck
   - Сохранение контейнера при сбоях для отладки

#### Оптимизации фронтенда:

1. **Оптимизация Node.js-окружения**:
   - Раздельная установка production и development зависимостей
   - Условная сборка приложения в зависимости от режима
   - Запуск от непривилегированного пользователя в production

2. **Улучшенная разработка**:
   - Hot-reload при изменении исходного кода
   - Монтирование исходных файлов для live-редактирования
   - Настраиваемые параметры healthcheck
   - Гибкое управление доступом к портам

#### Оптимизации Nginx:

1. **Улучшенная безопасность SSL**:
   - Поддержка только современных протоколов (TLSv1.2, TLSv1.3)
   - Настройка безопасных шифров
   - Оптимизация SSL-сессий
   - Заголовок HSTS для защиты от атак понижения протокола

2. **Защитные HTTP-заголовки**:
   - X-Content-Type-Options: защита от MIME-снифинга
   - X-Frame-Options: защита от кликджекинга
   - X-XSS-Protection: базовая защита от XSS-атак

3. **Оптимизация производительности**:
   - Настройка буферов и таймаутов
   - Включение сжатия gzip для экономии трафика
   - Оптимизация TCP-соединений (tcp_nodelay, tcp_nopush)
   - Отключение показа версии сервера (server_tokens off)

## Утилиты и скрипты

В проекте есть несколько полезных скриптов для управления развертыванием и обслуживанием:

### Скрипт развертывания

Для быстрого развертывания проекта используйте скрипт `scripts/deploy.sh`:

```bash
# Развертывание в продакшн режиме
./scripts/deploy.sh --prod

# Развертывание в режиме разработки
./scripts/deploy.sh --dev
```

Скрипт автоматически:
- Проверяет наличие Docker и Docker Compose
- Создает .env файл из .env.example (если нужно)
- Настраивает переменные окружения в зависимости от режима
- Генерирует сертификаты для MinIO и Nginx
- Создает необходимые директории
- Запускает контейнеры

### Резервное копирование и восстановление

#### Создание резервных копий

Для создания резервных копий баз данных и хранилища используйте скрипт `scripts/backup.sh`:

```bash
# Создание резервных копий в директории ./backups
./scripts/backup.sh

# Создание резервных копий в указанной директории
./scripts/backup.sh /path/to/backup/directory
```

Скрипт создает резервные копии:
- PostgreSQL
- MongoDB
- Redis
- MinIO

#### Восстановление из резервных копий

Для восстановления из резервных копий используйте скрипт `scripts/restore.sh`:

```bash
# Восстановление всех сервисов
./scripts/restore.sh /path/to/postgres/backup.sql /path/to/mongo/backup /path/to/redis/backup.rdb /path/to/minio/backup

# Восстановление только PostgreSQL
./scripts/restore.sh /path/to/postgres/backup.sql
```

#### Хранение данных

Данные хранятся в следующих директориях:
- PostgreSQL: `/home/admin/tg-bot/data`
- MongoDB: `./mongo_data`
- Redis: `./redis_data`
- MinIO: `./minio_data`

Регулярно создавайте резервные копии этих директорий с помощью скрипта `scripts/backup.sh`.

## Устранение неполадок

### Проблемы с сертификатами

Если возникают проблемы с SSL-сертификатами:
1. Проверьте, что сертификаты правильно сгенерированы и находятся в нужных директориях
2. Убедитесь, что имена в сертификатах соответствуют доменным именам в конфигурации
3. Перезапустите контейнеры: `docker-compose restart nginx minio`

### Проблемы с подключением к базам данных

Проверьте логи соответствующих контейнеров:
```bash
docker-compose logs postgres
docker-compose logs mongo
docker-compose logs redis
```

## Лицензия

[Укажите информацию о лицензии]
