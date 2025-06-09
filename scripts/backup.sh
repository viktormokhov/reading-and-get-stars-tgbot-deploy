#!/bin/bash

# Скрипт для создания резервных копий баз данных и хранилища MinIO
# Использование: ./backup.sh [каталог_для_бэкапов]

# Определение пути к корневой директории проекта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Переход в корневую директорию проекта
cd "$PROJECT_ROOT"
echo "Рабочая директория: $(pwd)"

# Настройка переменных
BACKUP_DIR=${1:-"./backups"}
DATE=$(date +%Y%m%d_%H%M%S)
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

# Создание директории для бэкапов
mkdir -p "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR/postgres"
mkdir -p "$BACKUP_DIR/mongo"
mkdir -p "$BACKUP_DIR/redis"
mkdir -p "$BACKUP_DIR/minio"

echo "Создание резервных копий в $BACKUP_DIR"

# Бэкап PostgreSQL
echo "Создание резервной копии PostgreSQL..."
docker exec -t $POSTGRES_CONTAINER pg_dumpall -c -U $POSTGRES_USER > "$BACKUP_DIR/postgres/postgres_$DATE.sql"
if [ $? -eq 0 ]; then
    echo "Резервная копия PostgreSQL создана: $BACKUP_DIR/postgres/postgres_$DATE.sql"
else
    echo "Ошибка при создании резервной копии PostgreSQL"
fi

# Бэкап MongoDB
echo "Создание резервной копии MongoDB..."
docker exec -t $MONGO_CONTAINER mongodump --username $MONGO_INITDB_ROOT_USERNAME --password $MONGO_INITDB_ROOT_PASSWORD --authenticationDatabase admin --out /backups/mongo_$DATE
if [ $? -eq 0 ]; then
    echo "Резервная копия MongoDB создана: $BACKUP_DIR/mongo/mongo_$DATE"
else
    echo "Ошибка при создании резервной копии MongoDB"
fi

# Бэкап Redis
echo "Создание резервной копии Redis..."
docker exec -t $REDIS_CONTAINER redis-cli -a $REDIS_PASSWORD --rdb /backups/redis_$DATE.rdb
if [ $? -eq 0 ]; then
    echo "Резервная копия Redis создана: $BACKUP_DIR/redis/redis_$DATE.rdb"
else
    echo "Ошибка при создании резервной копии Redis"
fi

# Бэкап MinIO (требуется клиент mc)
echo "Создание резервной копии MinIO..."
docker exec -t $MINIO_CONTAINER sh -c "mc alias set local http://localhost:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD && mc mirror local /backups/minio_$DATE"
if [ $? -eq 0 ]; then
    echo "Резервная копия MinIO создана: $BACKUP_DIR/minio/minio_$DATE"
else
    echo "Ошибка при создании резервной копии MinIO"
fi

echo "Резервное копирование завершено."
echo "Все резервные копии сохранены в каталоге $BACKUP_DIR"

# Очистка старых бэкапов (оставляем последние 5)
echo "Очистка старых резервных копий..."
find "$BACKUP_DIR/postgres" -name "postgres_*.sql" | sort -r | tail -n +6 | xargs -r rm
find "$BACKUP_DIR/mongo" -name "mongo_*" -type d | sort -r | tail -n +6 | xargs -r rm -rf
find "$BACKUP_DIR/redis" -name "redis_*.rdb" | sort -r | tail -n +6 | xargs -r rm
find "$BACKUP_DIR/minio" -name "minio_*" -type d | sort -r | tail -n +6 | xargs -r rm -rf

echo "Готово!"
