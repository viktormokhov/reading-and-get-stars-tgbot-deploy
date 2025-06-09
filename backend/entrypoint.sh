#!/bin/sh
set -e

# Создать директорию для sshd (если не существует)
mkdir -p /run/sshd

# SSH host-ключи, если их нет
ssh-keygen -A

# Только IPv4
grep -q "^AddressFamily inet" /etc/ssh/sshd_config || echo "AddressFamily inet" >> /etc/ssh/sshd_config

# Пароль для root (внимание: только для DEV!)
echo 'root:root' | chpasswd

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

# Запустить sshd в фоне
/usr/sbin/sshd -D &

# Запустить Uvicorn
if [ "$DEV_MODE" != "true" ]; then
    uvicorn main:app --host 0.0.0.0 --port 8000
    status=$?
    if [ $status -ne 0 ]; then
        echo "App crashed with status $status. Keeping container alive for debugging..."
        tail -f /dev/null
    fi
else
    echo "DEV_MODE enabled, uvicorn не запускается."
    tail -f /dev/null
fi
