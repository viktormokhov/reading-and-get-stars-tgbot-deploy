#!/bin/bash

# Скрипт для развертывания проекта
# Использование: ./deploy.sh [--prod|--dev]

# Настройка переменных
MODE="prod"  # По умолчанию - продакшн режим

# Обработка аргументов
if [ "$1" == "--dev" ]; then
    MODE="dev"
    echo "Запуск в режиме разработки"
elif [ "$1" == "--prod" ]; then
    MODE="prod"
    echo "Запуск в продакшн режиме"
elif [ ! -z "$1" ]; then
    echo "Неизвестный аргумент: $1"
    echo "Использование: $0 [--prod|--dev]"
    exit 1
fi

# Проверка наличия Docker и Docker Compose
if ! command -v docker &> /dev/null; then
    echo "Docker не установлен. Установите Docker перед запуском скрипта."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose не установлен. Установите Docker Compose перед запуском скрипта."
    exit 1
fi

# Проверка наличия .env файла
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        echo "Файл .env не найден. Создание из .env.example..."
        cp .env.example .env
        echo "Файл .env создан. Пожалуйста, отредактируйте его и укажите свои значения."
        exit 1
    else
        echo "Файлы .env и .env.example не найдены. Невозможно продолжить."
        exit 1
    fi
fi

# Настройка режима разработки в .env
if [ "$MODE" == "dev" ]; then
    echo "Настройка переменных окружения для режима разработки..."
    
    # Обновление .env для режима разработки
    sed -i 's/^DEV_MODE=.*/DEV_MODE=true/' .env
    sed -i 's/^NODE_DEV_MODE=.*/NODE_DEV_MODE=true/' .env
    sed -i 's/^BACKEND_DEV_MODE=.*/BACKEND_DEV_MODE=true/' .env
    sed -i 's/^BACKEND_DEV_TOOLS=.*/BACKEND_DEV_TOOLS=true/' .env
    sed -i 's/^BACKEND_INSTALL_SSH=.*/BACKEND_INSTALL_SSH=true/' .env
    sed -i 's/^BACKEND_RUN_APP_IN_DEV=.*/BACKEND_RUN_APP_IN_DEV=true/' .env
    sed -i 's/^FRONTEND_DEV_TOOLS=.*/FRONTEND_DEV_TOOLS=true/' .env
    sed -i 's/^FRONTEND_EXPOSE_PORT=.*/FRONTEND_EXPOSE_PORT=0.0.0.0/' .env
    
    echo "Режим разработки настроен."
else
    echo "Настройка переменных окружения для продакшн режима..."
    
    # Обновление .env для продакшн режима
    sed -i 's/^DEV_MODE=.*/DEV_MODE=false/' .env
    sed -i 's/^NODE_DEV_MODE=.*/NODE_DEV_MODE=false/' .env
    sed -i 's/^BACKEND_DEV_MODE=.*/BACKEND_DEV_MODE=false/' .env
    sed -i 's/^BACKEND_DEV_TOOLS=.*/BACKEND_DEV_TOOLS=false/' .env
    sed -i 's/^BACKEND_INSTALL_SSH=.*/BACKEND_INSTALL_SSH=false/' .env
    sed -i 's/^BACKEND_RUN_APP_IN_DEV=.*/BACKEND_RUN_APP_IN_DEV=false/' .env
    sed -i 's/^FRONTEND_DEV_TOOLS=.*/FRONTEND_DEV_TOOLS=false/' .env
    sed -i 's/^FRONTEND_EXPOSE_PORT=.*/FRONTEND_EXPOSE_PORT=127.0.0.1/' .env
    
    echo "Продакшн режим настроен."
fi

# Генерация сертификатов
echo "Генерация сертификатов..."

# MinIO сертификаты
if [ ! -f ./minio_data/certs/private.key ] || [ ! -f ./minio_data/certs/public.crt ]; then
    echo "Генерация сертификатов для MinIO..."
    
    # Проверка наличия скрипта
    if [ -f ./minio_data/certs/create_certs.sh ]; then
        chmod +x ./minio_data/certs/create_certs.sh
        ./minio_data/certs/create_certs.sh
    else
        echo "Скрипт для генерации сертификатов MinIO не найден."
        echo "Пожалуйста, создайте сертификаты вручную."
    fi
else
    echo "Сертификаты MinIO уже существуют."
fi

# Nginx сертификаты
if [ ! -f ./nginx/certs/privkey.pem ] || [ ! -f ./nginx/certs/fullchain.pem ]; then
    echo "Генерация сертификатов для Nginx..."
    
    # Проверка наличия скрипта
    if [ -f ./nginx/certs/create_certs.sh ]; then
        chmod +x ./nginx/certs/create_certs.sh
        ./nginx/certs/create_certs.sh
    else
        echo "Скрипт для генерации сертификатов Nginx не найден."
        echo "Пожалуйста, создайте сертификаты вручную."
    fi
else
    echo "Сертификаты Nginx уже существуют."
fi

# Создание необходимых директорий
echo "Создание необходимых директорий..."
mkdir -p ./data
mkdir -p ./mongo_data/backups
mkdir -p ./redis_data
mkdir -p ./minio_data/config

# Запуск контейнеров
echo "Запуск контейнеров..."
docker-compose down
docker-compose up -d

# Проверка статуса
echo "Проверка статуса контейнеров..."
docker-compose ps

echo "Развертывание завершено!"
if [ "$MODE" == "dev" ]; then
    echo "Проект запущен в режиме разработки."
    echo "Для доступа к бэкенду по SSH: ssh root@localhost -p 7721"
    echo "Пароль указан в переменной BACKEND_SSH_PASSWORD в файле .env"
else
    echo "Проект запущен в продакшн режиме."
fi

echo "Для просмотра логов используйте: docker-compose logs -f"
echo "Для остановки проекта используйте: docker-compose down"