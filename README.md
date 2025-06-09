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

Создайте файл `.env` в корне проекта со следующими переменными:

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

# Telegram Bot
TG_BOT_TOKEN=your_telegram_bot_token
TG_ADMIN_ID=your_telegram_id

# AI Services (если используются)
OPENAI_API_KEY=your_openai_api_key
XAI_API_KEY=your_xai_api_key
HUGGINGFACE_API_KEY=your_huggingface_api_key

# Режим разработки (true/false)
NODE_DEV_MODE=false
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

1. **Самоподписанные сертификаты** (для тестирования):

```bash
mkdir -p nginx/certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/certs/privkey.pem \
  -out nginx/certs/fullchain.pem \
  -subj "/C=RU/ST=Region/L=City/O=Organization/CN=read-q.cloudns.ch"
```

2. **Let's Encrypt** (для продакшена):
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

## Резервное копирование

Данные хранятся в следующих директориях:
- PostgreSQL: `/home/admin/tg-bot/data`
- MongoDB: `./mongo_data`
- Redis: `./redis_data`
- MinIO: `./minio_data`

Регулярно создавайте резервные копии этих директорий.

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