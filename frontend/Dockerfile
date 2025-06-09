FROM node:22-alpine AS base
WORKDIR /app

# Аргумент для режима
ARG NODE_DEV_MODE=false
ENV NODE_DEV_MODE=${NODE_DEV_MODE}

COPY package.json package-lock.json ./

RUN npm install -g npm@latest
RUN npm install

COPY . .

# Сборка production только если не dev
RUN if [ "$NODE_DEV_MODE" != "true" ]; then npm run build; fi

EXPOSE 3000

CMD if [ "$NODE_DEV_MODE" = "true" ]; then npm run dev; else npm run start; fi
