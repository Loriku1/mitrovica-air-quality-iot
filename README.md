# Mitrovica Air Quality – IoT Platform

An IoT-based air quality monitoring platform designed to monitor
PM2.5 and PM10 pollution levels across Mitrovica, Kosovo.

## 1. Project Overview

The platform collects air quality measurements from IoT sensors,
processes incoming data, stores historical measurements and
generates alerts when pollution thresholds are exceeded.

The system is designed to support 1,000 sensors sending
measurements every 5 seconds.

## 2. Main Challenge

The system must handle:

- 1,000 IoT sensors.
- 200 incoming messages per second.
- PM2.5 and PM10 measurements.
- Time-series data storage.
- Pollution alerts within 10 seconds (p95).
- Zero data loss during sustained ingestion.

## 3. Microservices Architecture

The system consists of three core microservices.

| Service | Port | Responsibility |
|---|---:|---|
| Ingestion Service | 3101 | Receives and validates sensor measurements |
| Storage Service | 3102 | Owns and stores historical air quality measurements |
| Alert Service | 3103 | Evaluates pollution thresholds and generates alerts |

Each microservice is designed with independent data ownership.

## 4. Data Retention

- Raw measurements: 7 days.
- One-minute aggregates: 90 days.

## 5. Technology Stack

- Node.js
- TypeScript
- Express.js
- PostgreSQL / TimescaleDB
- RabbitMQ
- Docker
- Kubernetes
- Prometheus
- Grafana
- OpenTelemetry

## 6. Getting Started

### Requirements

- Node.js 22+
- npm
- Docker Desktop (for future infrastructure components)

### Installation

```bash
npm install