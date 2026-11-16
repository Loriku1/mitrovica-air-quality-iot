FROM node:22-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY tsconfig.json ./
COPY services/storage-service ./services/storage-service

EXPOSE 3102

CMD ["npm", "run", "dev:storage"]
