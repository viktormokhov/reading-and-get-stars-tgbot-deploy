# Этап сборки зависимостей
FROM node:22-alpine AS deps
WORKDIR /app

# Аргументы для режима разработки
ARG NODE_DEV_MODE=false
ARG INSTALL_DEV_TOOLS=false

# Копирование файлов зависимостей
COPY package.json package-lock.json ./

# Установка зависимостей с учетом режима
RUN npm install -g npm@latest && \
    npm config set fetch-retry-mintimeout 20000 && \
    npm config set fetch-retry-maxtimeout 120000 && \
    npm config set fetch-retries 5 && \
    npm config set registry https://registry.npmjs.org/ && \
    if [ "$NODE_DEV_MODE" = "true" ]; then \
        npm install --no-strict-ssl --legacy-peer-deps --prefer-offline --network-timeout=300000; \
    else \
        npm install --only=production --no-strict-ssl --legacy-peer-deps --prefer-offline --network-timeout=300000; \
    fi

# Этап сборки (только для production)
FROM deps AS builder
WORKDIR /app

# Копирование исходного кода
COPY . .

# Сборка production только если не dev
RUN if [ "$NODE_DEV_MODE" != "true" ]; then npm run build; fi

# Установка инструментов разработки (если нужно)
RUN if [ "$INSTALL_DEV_TOOLS" = "true" ]; then \
        apk add --no-cache bash curl vim nano; \
    fi

# Финальный образ
FROM node:22-alpine AS runner
WORKDIR /app

# Переменные окружения
ARG NODE_DEV_MODE=false
ENV NODE_DEV_MODE=${NODE_DEV_MODE}
ENV NODE_ENV=${NODE_DEV_MODE:+development}
ENV NODE_ENV=${NODE_ENV:-production}

# Копирование зависимостей и сборки из предыдущих этапов
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

# Копирование исходного кода или собранных файлов в зависимости от режима
COPY --from=builder /app/src ./src
COPY --from=builder /app/public ./public
RUN if [ "$NODE_DEV_MODE" != "true" ] && [ -d "/app/build" ]; then \
        cp -r /app/build ./build; \
    fi

# Безопасность: запуск от непривилегированного пользователя
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001 && \
    chown -R nextjs:nodejs /app

# Переключение на непривилегированного пользователя (только в production)
USER nextjs

# Порт для приложения
EXPOSE 3000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD wget -qO- http://localhost:3000/api/health || exit 1

# Запуск приложения в зависимости от режима
CMD if [ "$NODE_DEV_MODE" = "true" ]; then npm run dev; else npm run start; fi
