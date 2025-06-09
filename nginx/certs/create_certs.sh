#!/bin/bash

# === Настройки (отредактируйте под себя!) ===
CERTS_DIR="./nginx/certs"
CONFIG="nginx_openssl.cnf"
DOMAIN="read-q.cloudns.ch"

# --- Создаём OpenSSL конфиг ---
cat > "$CONFIG" <<EOF
[ req ]
default_bits       = 2048
prompt             = no
default_md         = sha256
req_extensions     = req_ext
distinguished_name = dn

[ dn ]
C=RU
ST=Region
L=City
O=Company
OU=IT
CN=${DOMAIN}

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1   = ${DOMAIN}
DNS.2   = localhost
IP.1    = 127.0.0.1
IP.2    = 10.10.10.4
EOF

# --- Создаём директорию для сертификатов ---
mkdir -p "$CERTS_DIR"

# --- Генерируем сертификат ---
openssl req -new -nodes -x509 -days 365 \
  -keyout "$CERTS_DIR/privkey.pem" \
  -out "$CERTS_DIR/fullchain.pem" \
  -config "$CONFIG"

echo
echo "Сертификат сгенерирован:"
echo "  $CERTS_DIR/fullchain.pem"
echo "  $CERTS_DIR/privkey.pem"
echo
echo "SAN (Subject Alternative Name) из сертификата:"
openssl x509 -in "$CERTS_DIR/fullchain.pem" -text | grep -A1 "Subject Alternative Name"

echo
echo "Папку $CERTS_DIR подключается к Nginx как volume:"
echo "  - ./nginx/certs:/etc/nginx/certs:ro"