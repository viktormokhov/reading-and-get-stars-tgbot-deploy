#!/bin/sh
set -e

# Настройка SSH сервера (только если INSTALL_SSH=true)
if [ "$INSTALL_SSH" = "true" ]; then
    echo "Настройка SSH сервера..."

    # Создать директорию для sshd (если не существует)
    mkdir -p /run/sshd

    # SSH host-ключи, если их нет
    ssh-keygen -A

    # Только IPv4
    grep -q "^AddressFamily inet" /etc/ssh/sshd_config || echo "AddressFamily inet" >> /etc/ssh/sshd_config

    # Настройка пароля для root (используем переменную окружения или значение по умолчанию)
    SSH_ROOT_PASSWORD=${SSH_ROOT_PASSWORD:-"changeme"}

    # Если мы в режиме разработки, разрешаем root логин и аутентификацию по паролю
    if [ "$DEV_MODE" = "true" ]; then
        echo "Настройка SSH для режима разработки..."
        echo "root:${SSH_ROOT_PASSWORD}" | chpasswd

        # Включить PermitRootLogin yes
        if grep -q "^PermitRootLogin" /etc/ssh/sshd_config; then
            sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
        else
            echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
        fi

        # PasswordAuthentication yes
        if grep -q "^PasswordAuthentication" /etc/ssh/sshd_config; then
            sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
        else
            echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
        fi
    else
        # В продакшн режиме отключаем небезопасные настройки
        echo "Настройка SSH для продакшн режима..."

        # Отключить PermitRootLogin
        if grep -q "^PermitRootLogin" /etc/ssh/sshd_config; then
            sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
        else
            echo "PermitRootLogin no" >> /etc/ssh/sshd_config
        fi

        # Отключить PasswordAuthentication
        if grep -q "^PasswordAuthentication" /etc/ssh/sshd_config; then
            sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
        else
            echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
        fi
    fi

    echo "Запуск SSH сервера..."
    # Запустить sshd в фоне
    /usr/sbin/sshd -D &

    # Проверка запуска SSH
    if [ $? -ne 0 ]; then
        echo "Ошибка запуска SSH сервера!"
    else
        echo "SSH сервер запущен успешно."
    fi
fi

# Запустить Uvicorn
if [ "$DEV_MODE" != "true" ]; then
    echo "Запуск приложения в продакшн режиме..."
    uvicorn main:app --host 0.0.0.0 --port 8000
    status=$?
    if [ $status -ne 0 ]; then
        echo "Приложение завершилось с ошибкой (статус $status). Контейнер остается активным для отладки..."
        tail -f /dev/null
    fi
else
    echo "DEV_MODE включен, приложение запускается в режиме разработки..."
    # В режиме разработки можно запустить с автоперезагрузкой
    if [ "$RUN_APP_IN_DEV" = "true" ]; then
        echo "Запуск uvicorn с автоперезагрузкой..."
        uvicorn main:app --host 0.0.0.0 --port 8000 --reload
    else
        echo "Приложение не запускается автоматически в режиме разработки."
        echo "Для запуска вручную используйте: uvicorn main:app --host 0.0.0.0 --port 8000 --reload"
        tail -f /dev/null
    fi
fi
