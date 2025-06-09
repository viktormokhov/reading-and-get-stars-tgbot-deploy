#!/bin/bash

# Скрипт для восстановления баз данных и хранилища MinIO из резервных копий
# Использование: ./restore.sh [путь_к_бэкапу_postgres] [путь_к_бэкапу_mongo] [путь_к_бэкапу_redis] [путь_к_бэкапу_minio]

# Проверка аргументов
if [ $# -lt 1 ]; then
    echo "Использование: $0 [путь_к_бэкапу_postgres] [путь_к_бэкапу_mongo] [путь_к_бэкапу_redis] [путь_к_бэкапу_minio]"
    echo "Пример: $0 ./backups/postgres/postgres_20250609_120000.sql ./backups/mongo/mongo_20250609_120000 ./backups/redis/redis_20250609_120000.rdb ./backups/minio/minio_20250609_120000"
    exit 1
fi

# Настройка переменных
POSTGRES_BACKUP=$1
MONGO_BACKUP=$2
REDIS_BACKUP=$3
MINIO_BACKUP=$4

POSTGRES_CONTAINER="tg-bot-postgres-1"
MONGO_CONTAINER="tg-bot-mongo-1"
REDIS_CONTAINER="tg-bot-redis-1"
MINIO_CONTAINER="tg-bot-minio-1"

# Загрузка переменных окружения
if [ -f .env ]; then
    source .env
else
    echo "Файл .env не найден."
    if [ -f .env.example ]; then
        echo "Найден файл .env.example. Хотите создать .env из него? (y/n)"
        read -r answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            cp .env.example .env
            echo "Файл .env создан из .env.example. Пожалуйста, отредактируйте его и запустите скрипт снова."
            exit 1
        fi
    fi
    echo "Продолжение с значениями по умолчанию (не рекомендуется)."
    echo "Рекомендуется создать файл .env с правильными учетными данными."
    echo "Нажмите Ctrl+C для отмены или Enter для продолжения с значениями по умолчанию."
    read -r

    POSTGRES_USER="postgres"
    POSTGRES_DB="tgbot"
    MONGO_INITDB_ROOT_USERNAME="mongodb"
    MONGO_INITDB_ROOT_PASSWORD="password"
    REDIS_PASSWORD="password"
    MINIO_ROOT_USER="minio"
    MINIO_ROOT_PASSWORD="password"
fi

# Функция для проверки существования файла/директории
check_exists() {
    if [ ! -e "$1" ]; then
        echo "Ошибка: $1 не существует"
        exit 1
    fi
}

# Восстановление PostgreSQL
if [ ! -z "$POSTGRES_BACKUP" ]; then
    check_exists "$POSTGRES_BACKUP"
    echo "Восстановление PostgreSQL из $POSTGRES_BACKUP..."

    # Остановка зависимых сервисов
    echo "Остановка зависимых сервисов..."
    docker-compose stop backend frontend

    # Восстановление
    cat "$POSTGRES_BACKUP" | docker exec -i $POSTGRES_CONTAINER psql -U $POSTGRES_USER

    if [ $? -eq 0 ]; then
        echo "PostgreSQL успешно восстановлен"
    else
        echo "Ошибка при восстановлении PostgreSQL"
    fi

    # Запуск зависимых сервисов
    echo "Запуск зависимых сервисов..."
    docker-compose start backend frontend
fi

# Восстановление MongoDB
if [ ! -z "$MONGO_BACKUP" ]; then
    check_exists "$MONGO_BACKUP"
    echo "Восстановление MongoDB из $MONGO_BACKUP..."

    # Остановка зависимых сервисов
    echo "Остановка зависимых сервисов..."
    docker-compose stop backend frontend

    # Восстановление
    docker exec -i $MONGO_CONTAINER mongorestore --username $MONGO_INITDB_ROOT_USERNAME --password $MONGO_INITDB_ROOT_PASSWORD --authenticationDatabase admin --drop "$MONGO_BACKUP"

    if [ $? -eq 0 ]; then
        echo "MongoDB успешно восстановлен"
    else
        echo "Ошибка при восстановлении MongoDB"
    fi

    # Запуск зависимых сервисов
    echo "Запуск зависимых сервисов..."
    docker-compose start backend frontend
fi

# Восстановление Redis
if [ ! -z "$REDIS_BACKUP" ]; then
    check_exists "$REDIS_BACKUP"
    echo "Восстановление Redis из $REDIS_BACKUP..."

    # Остановка Redis
    echo "Остановка Redis..."
    docker-compose stop redis

    # Копирование файла RDB в контейнер
    docker cp "$REDIS_BACKUP" $REDIS_CONTAINER:/data/dump.rdb

    # Запуск Redis
    echo "Запуск Redis..."
    docker-compose start redis

    echo "Redis успешно восстановлен"
fi

# Восстановление MinIO
if [ ! -z "$MINIO_BACKUP" ]; then
    check_exists "$MINIO_BACKUP"
    echo "Восстановление MinIO из $MINIO_BACKUP..."

    # Восстановление
    docker exec -i $MINIO_CONTAINER sh -c "mc alias set local http://localhost:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD && mc mirror --overwrite $MINIO_BACKUP local"

    if [ $? -eq 0 ]; then
        echo "MinIO успешно восстановлен"
    else
        echo "Ошибка при восстановлении MinIO"
    fi
fi

echo "Восстановление завершено."
