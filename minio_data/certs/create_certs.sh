#!/bin/bash

# === Настройки (отредактируйте под себя!) ===
CERTS_DIR="./minio_data/certs"
CONFIG="minio_openssl.cnf"

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
CN=minio

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1   = minio
DNS.2   = localhost
IP.1    = 127.0.0.1
IP.2    = 10.10.10.7
EOF

# --- Создаём директорию для сертификатов ---
mkdir -p "$CERTS_DIR"

# --- Генерируем сертификат ---
openssl req -new -nodes -x509 -days 365 \
  -keyout "$CERTS_DIR/private.key" \
  -out "$CERTS_DIR/public.crt" \
  -config "$CONFIG"

echo
echo "Сертификат сгенерирован:"
echo "  $CERTS_DIR/public.crt"
echo "  $CERTS_DIR/private.key"
echo
echo "SAN (Subject Alternative Name) из сертификата:"
openssl x509 -in "$CERTS_DIR/public.crt" -text | grep -A1 "Subject Alternative Name"

echo
echo "Папку $CERTS_DIR подключайте к MinIO как volume:"
echo "  - ./minio_dara/certs:/root/.minio/certs"
