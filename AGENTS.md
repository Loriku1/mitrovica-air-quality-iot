# AGENTS.md

## 1. Project Overview

This project is an IoT-based air quality monitoring platform
for Mitrovica, Kosovo.

The system processes PM2.5 and PM10 measurements from
distributed IoT sensors.

## 2. Technology Stack

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

## 3. Architecture Rules

The system follows a microservices architecture.

Each microservice must:

- Have a clearly defined responsibility.
- Own its data.
- Expose its own API.
- Maintain an independent health endpoint.
- Avoid direct access to another service's database.

## 4. Microservices

### Ingestion Service

Path: services/ingestion-service

Responsibilities:
- Receive sensor measurements.
- Validate incoming data.
- Publish measurement events.

Port: 3101

### Storage Service

Path: services/storage-service

Responsibilities:
- Store air quality measurements.
- Manage time-series data.
- Support historical queries.

Port: 3102

### Alert Service

Path: services/alert-service

Responsibilities:
- Evaluate pollution thresholds.
- Generate alerts.
- Track alert events.

Port: 3103

## 5. Coding Standards

- Use TypeScript.
- Use strict type checking.
- Prefer async/await.
- Validate incoming API requests.
- Handle errors explicitly.
- Use meaningful variable and function names.
- Keep services modular.

## 6. Security Rules

- Never commit secrets or API keys.
- Use environment variables for configuration.
- Validate external input.
- Follow least-privilege principles.

## 7. Git Rules

- Use meaningful commit messages.
- Do not commit node_modules.
- Do not commit environment secrets.
- Keep changes focused and documented.

## 8. Important Restrictions

- Do not merge all microservices into one application.
- Do not allow services to share database ownership.
- Do not modify architecture decisions without documenting them.
- Do not remove existing health endpoints.
- Do not introduce unnecessary dependencies.

## 9. Documentation

Keep the following updated:

- README.md
- docs/architecture.md
- docs/slo.md
- docs/risks.md
- docs/adr/
- docs/journal/

Any significant architectural change must be documented
in an Architecture Decision Record (ADR).