@'
# Mitrovica Air Quality – IoT Platform

An IoT-based air quality monitoring platform designed to monitor PM2.5 and PM10 pollution levels across Mitrovica, Kosovo.

## 1. Project Overview

The platform collects air quality measurements from IoT sensors, processes incoming data, stores historical measurements and generates alerts when pollution thresholds are exceeded.

The system is designed to support 1,000 sensors sending measurements every 5 seconds.

## 2. Main Challenge

The system must handle:

- 1,000 IoT sensors.
- 200 incoming messages per second.
- PM2.5 and PM10 measurements.
- Time-series data storage.
- Pollution alerts within 10 seconds (p95).
- Zero data loss during sustained ingestion.

## 3. Microservices Architecture

| Service | Port | Responsibility |
|---|---:|---|
| ingestion-service | 3101 | Receives and validates sensor measurements |
| storage-service | 3102 | Stores historical air quality measurements |
| alert-service | 3103 | Evaluates pollution thresholds and generates alerts |

Each microservice has independent data ownership.

## 4. Data Retention

- Raw measurements: 7 days.
- One-minute aggregates: 90 days.

## 5. Technology Stack

- Node.js 22
- TypeScript
- Express.js
- PostgreSQL / TimescaleDB (planned)
- RabbitMQ (planned)
- Docker
- Kubernetes (planned)
- Prometheus and Grafana (planned)
- OpenTelemetry (planned)

## 6. Nisja

### Requirements

- Node.js 22+
- npm

### Installation

Install project dependencies:

    npm install

### Start all three microservices

    npm run dev:all

### Health endpoints

- Ingestion: http://localhost:3101/health
- Storage: http://localhost:3102/health
- Alert: http://localhost:3103/health

### Type checking

    npm run typecheck

## 7. Current Implementation Status

Currently implemented:

- Three runnable Express and TypeScript service skeletons.
- Independent HTTP health endpoints.
- OpenAPI contracts for all three services.
- C4 architecture documentation.
- SLO definitions and ADR documentation.

Planned for subsequent development:

- RabbitMQ event processing.
- PostgreSQL and TimescaleDB persistence.
- Transactional outbox and idempotent consumers.
- Kubernetes deployment.
- Prometheus, Grafana and OpenTelemetry monitoring.
'@ | Set-Content README.md -Encoding utf8