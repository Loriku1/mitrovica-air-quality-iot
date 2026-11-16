FROM node:22-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY tsconfig.json ./
COPY services/ingestion-service ./services/ingestion-service

EXPOSE 3101

CMD ["npm", "run", "dev:ingestion"]
