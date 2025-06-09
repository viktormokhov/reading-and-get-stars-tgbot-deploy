#!/bin/bash

# Скрипт для полной пересборки проекта с нуля
# Использование: ./rebuild.sh [--force]

# Определение пути к корневой директории проекта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Переход в корневую директорию проекта
cd "$PROJECT_ROOT"
echo "Рабочая директория: $(pwd)"

# Флаг для пропуска подтверждений (для автоматизации)
FORCE=false

# Обработка аргументов
if [ "$1" == "--force" ]; then
    FORCE=true
    echo "Режим автоматического подтверждения активирован"
fi

# Проверка наличия Docker и Docker Compose
if ! docker --version > /dev/null 2>&1; then
    echo "Docker не установлен. Установите Docker перед запуском скрипта."
    exit 1
fi

if ! docker compose --version > /dev/null 2>&1; then
    echo "Docker Compose не установлен. Установите Docker Compose перед запуском скрипта."
    exit 1
fi

# Функция для запроса подтверждения
confirm() {
    if [ "$FORCE" = true ]; then
        return 0
    fi

    read -p "$1 [y/N]: " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Предупреждение о потере данных
echo "ВНИМАНИЕ: Этот скрипт полностью удалит все контейнеры, образы, тома и данные проекта!"
echo "Все данные будут потеряны! Рекомендуется сделать резервную копию перед продолжением."

if ! confirm "Вы уверены, что хотите продолжить?"; then
    echo "Операция отменена."
    exit 0
fi

echo "Начинаем процесс полной пересборки..."

# Остановка и удаление всех контейнеров
echo "Остановка и удаление контейнеров..."
docker compose down

# Удаление всех томов Docker
if confirm "Удалить все тома Docker, связанные с проектом?"; then
    echo "Удаление томов Docker..."
    docker volume rm $(docker volume ls -q | grep tg-bot) 2>/dev/null || true
    docker volume rm nginx-cache 2>/dev/null || true
fi

# Удаление локальных данных
if confirm "Удалить все локальные данные проекта (mongo_data, redis_data, minio_data)?"; then
    echo "Удаление локальных данных..."

    # Удаление данных MongoDB
    if [ -d "./mongo_data" ]; then
        echo "Удаление данных MongoDB..."
        rm -rf ./mongo_data/*
        mkdir -p ./mongo_data/backups
    fi

    # Удаление данных Redis
    if [ -d "./redis_data" ]; then
        echo "Удаление данных Redis..."
        rm -rf ./redis_data/*
        mkdir -p ./redis_data
    fi

    # Удаление данных MinIO (сохраняем сертификаты)
    if [ -d "./minio_data" ]; then
        echo "Удаление данных MinIO (кроме сертификатов)..."
        find ./minio_data -mindepth 1 -maxdepth 1 -not -name "certs" -exec rm -rf {} \;
        mkdir -p ./minio_data/config
    fi

    # Удаление логов Nginx
    if [ -d "./nginx/logs" ]; then
        echo "Удаление логов Nginx..."
        rm -rf ./nginx/logs/*
        mkdir -p ./nginx/logs
    fi
fi

# Очистка директорий frontend и backend (опционально)
if confirm "Очистить директории frontend и backend (кроме файлов сборки)?"; then
    echo "Очистка директорий frontend и backend..."

    # Очистка frontend (сохраняем только Dockerfile)
    if [ -d "./frontend" ]; then
        echo "Очистка директории frontend..."
        find ./frontend -mindepth 1 -maxdepth 1 -not -name "Dockerfile" -exec rm -rf {} \;
    fi

    # Очистка backend (сохраняем Dockerfile и entrypoint.sh)
    if [ -d "./backend" ]; then
        echo "Очистка директории backend..."
        find ./backend -mindepth 1 -maxdepth 1 -not -name "Dockerfile" -not -name "entrypoint.sh" -exec rm -rf {} \;
    fi

    echo "Директории frontend и backend очищены."

    # Проверка наличия Git и скачивание кода из GitHub
    if command -v git > /dev/null 2>&1; then
        echo "Git установлен. Скачивание кода из GitHub..."

        # Скачивание кода для backend
        echo "Скачивание кода для backend..."
        if [ -d "backend-repo" ]; then
            echo "Директория backend-repo уже существует. Обновление кода..."
            cd backend-repo
            git pull
            cd ..
            if [ $? -eq 0 ]; then
                echo "Код для backend успешно обновлен."
            else
                echo "ОШИБКА: Не удалось обновить код для backend!"
                echo "Пересборка прервана."
                exit 1
            fi
        else
            git clone https://github.com/viktormokhov/reading-and-get-stars-tgbot-backend.git backend-repo
            if [ $? -ne 0 ]; then
                echo "ОШИБКА: Не удалось скачать код для backend!"
                echo "Пересборка прервана."
                exit 1
            fi
            echo "Код для backend успешно скачан."
        fi
        # Копирование исходного кода в директорию backend
        mkdir -p ./backend/src
        # Копирование файлов зависимостей в корень backend
        cp ./backend-repo/pyproject.toml ./backend-repo/poetry.lock ./backend/ 2>/dev/null || true
        cp ./backend-repo/README.md ./backend/ 2>/dev/null || true
        # Копирование исходного кода в backend/src
        cp -r ./backend-repo/src/* ./backend/src/ 2>/dev/null || true
        echo "Исходный код скопирован в директорию backend."

        # Скачивание кода для frontend
        echo "Скачивание кода для frontend..."
        if [ -d "frontend-repo" ]; then
            echo "Директория frontend-repo уже существует. Обновление кода..."
            cd frontend-repo
            git pull
            cd ..
            if [ $? -eq 0 ]; then
                echo "Код для frontend успешно обновлен."
            else
                echo "ОШИБКА: Не удалось обновить код для frontend!"
                echo "Пересборка прервана."
                exit 1
            fi
        else
            git clone https://github.com/viktormokhov/reading-and-get-stars-tgbot-frontend.git frontend-repo
            if [ $? -ne 0 ]; then
                echo "ОШИБКА: Не удалось скачать код для frontend!"
                echo "Пересборка прервана."
                exit 1
            fi
            echo "Код для frontend успешно скачан."
        fi
        # Копирование исходного кода в директорию frontend
        mkdir -p ./frontend/src
        mkdir -p ./frontend/public
        # Копирование файлов зависимостей в корень frontend
        cp ./frontend-repo/package.json ./frontend-repo/package-lock.json ./frontend/ 2>/dev/null || true
        # Копирование исходного кода в frontend
        cp -r ./frontend-repo/src/* ./frontend/src/ 2>/dev/null || true
        cp -r ./frontend-repo/public/* ./frontend/public/ 2>/dev/null || true
        echo "Исходный код скопирован в директорию frontend."
    else
        echo "ОШИБКА: Git не установлен. Невозможно скачать код из GitHub."
        echo "Пожалуйста, установите Git или скопируйте исходный код вручную в директории:"
        echo "- ./backend/src"
        echo "- ./frontend/src"
        echo "- ./frontend/public"
        echo "Пересборка прервана."
        exit 1
    fi
fi

# Удаление сертификатов (опционально)
if confirm "Удалить сертификаты и сгенерировать новые?"; then
    echo "Удаление сертификатов..."

    # Удаление сертификатов MinIO
    if [ -d "./minio_data/certs" ]; then
        rm -f ./minio_data/certs/private.key ./minio_data/certs/public.crt
    fi

    # Удаление сертификатов Nginx
    if [ -d "./nginx/certs" ]; then
        rm -f ./nginx/certs/privkey.pem ./nginx/certs/fullchain.pem
    fi
fi

# Удаление образов Docker (опционально)
if confirm "Удалить все образы Docker, связанные с проектом?"; then
    echo "Удаление образов Docker..."
    # Получаем список образов, связанных с проектом
    PROJECT_IMAGES=$(docker images | grep tg-bot | awk '{print $3}')
    if [ ! -z "$PROJECT_IMAGES" ]; then
        docker rmi $PROJECT_IMAGES
    else
        echo "Образы проекта не найдены."
    fi
fi

# Запуск скрипта развертывания
echo "Запуск скрипта развертывания..."
if confirm "Запустить в режиме разработки? (N = продакшн режим)"; then
    "$SCRIPT_DIR/deploy.sh" --dev
    if [ $? -ne 0 ]; then
        echo "ОШИБКА: Скрипт развертывания завершился с ошибкой!"
        echo "Пересборка прервана."
        exit 1
    fi
else
    "$SCRIPT_DIR/deploy.sh" --prod
    if [ $? -ne 0 ]; then
        echo "ОШИБКА: Скрипт развертывания завершился с ошибкой!"
        echo "Пересборка прервана."
        exit 1
    fi
fi

echo "Полная пересборка проекта завершена!"
