# ADR-001: Microservices Architecture and Data Ownership

## Status

Accepted

## Date

2026-11-13

## 1. Context

The Mitrovica Air Quality IoT Platform must process measurements from 1,000 IoT sensors sending data every 5 seconds.

This produces approximately 200 incoming measurement messages per second.

The platform must support independent measurement ingestion, time-series storage, and pollution alert processing.

A monolithic architecture could initially simplify development, but it would tightly couple these responsibilities and make independent scaling more difficult.

## 2. Decision

We will use a microservices architecture with three independent core services:

1. **Ingestion Service:** Receives and validates sensor measurements.
2. **Storage Service:** Stores raw measurements and one-minute aggregates.
3. **Alert Service:** Evaluates pollution thresholds and manages alerts.

Each service will own its data and database.

Services will communicate through HTTP for synchronous operations and RabbitMQ for asynchronous measurement events.

Dashboard read APIs will be provided by the Storage and Alert services instead of introducing a separate Dashboard API microservice.

## 3. Alternatives Considered

### Monolithic Architecture

All application logic and data access would exist in one application.

Advantages:
- Simpler initial development.
- Fewer deployment components.

Disadvantages:
- Tightly coupled responsibilities.
- Limited independent scaling.
- Changes to one component could affect the entire application.

### Microservices with Shared Database

Multiple services would exist, but all would access the same database.

Advantages:
- Independent service deployment.
- Simpler initial database management.

Disadvantages:
- Shared database creates coupling.
- Data ownership becomes unclear.
- Schema changes can affect multiple services.

## 4. Consequences

Positive consequences:

- Independent scaling of ingestion, storage, and alert processing.
- Clear ownership of business logic and data.
- Better isolation of service failures.
- Independent development and deployment.

Negative consequences:

- More complex deployment and monitoring.
- Network communication introduces additional failure scenarios.
- Data consistency and event delivery require additional mechanisms.

## 5. Summary

The microservices architecture was selected because the platform requires independent ingestion, storage, and alert processing.

Database ownership is separated between the three services to reduce coupling and support future scalability.