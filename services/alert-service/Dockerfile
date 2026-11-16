FROM node:22-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY tsconfig.json ./
COPY services/alert-service ./services/alert-service

EXPOSE 3103

CMD ["npm", "run", "dev:alert"]
