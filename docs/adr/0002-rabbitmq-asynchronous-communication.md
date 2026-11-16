# ADR-002: RabbitMQ and Asynchronous Communication

## Status

Accepted

## Date

2026-11-13

## 1. Context

The Mitrovica Air Quality IoT Platform is expected to receive approximately 200 measurement messages per second from 1,000 IoT sensors.

Each incoming measurement must be processed by two independent services:

- Storage Service, which persists measurements and creates aggregates.
- Alert Service, which evaluates pollution thresholds and generates alerts.

Using only synchronous HTTP communication would tightly couple the Ingestion Service to downstream services.

If one downstream service becomes unavailable, ingestion could be delayed or fail.

The platform therefore requires reliable asynchronous communication.

## 2. Decision

We will use RabbitMQ as the asynchronous message broker.

The communication flow will be:

1. Ingestion Service validates incoming measurements.
2. Ingestion Service stores the measurement metadata and an event in its transactional outbox.
3. An outbox publisher sends measurement events to RabbitMQ.
4. Storage Service consumes events and stores measurements.
5. Alert Service independently consumes events and evaluates pollution thresholds.

RabbitMQ will use durable queues and persistent messages.

Consumers will acknowledge messages only after successful processing.

Consumers will also implement idempotency to prevent duplicate processing.

## 3. Alternatives Considered

### Synchronous HTTP Communication

The Ingestion Service would send HTTP requests directly to Storage and Alert services.

Advantages:
- Simple communication model.
- Easy initial implementation.
- Immediate response from downstream services.

Disadvantages:
- Strong runtime dependency between services.
- Downstream failures can affect ingestion.
- Difficult to handle temporary service outages.

### Redis Streams

Redis Streams could be used as an event streaming mechanism.

Advantages:
- Lightweight.
- High performance.
- Supports consumer groups.

Disadvantages:
- Requires additional decisions about persistence and stream management.
- RabbitMQ provides a messaging model that better matches the current project requirements.

## 4. Consequences

Positive consequences:

- Ingestion, storage, and alert processing are decoupled.
- Storage and Alert services can consume events independently.
- Temporary consumer outages can be handled through message queues.
- Message buffering helps absorb processing spikes.
- Consumers can be scaled independently.

Negative consequences:

- RabbitMQ introduces another infrastructure component.
- Event delivery and processing require monitoring.
- Duplicate message delivery must be handled.
- The transactional outbox pattern adds implementation complexity.

## 5. Reliability Considerations

The transactional outbox pattern will be used to reduce the risk of losing accepted measurements between database persistence and message publishing.

RabbitMQ queues will be configured for durability and persistent messages.

Consumers will use manual acknowledgements after successful processing.

Idempotency keys will prevent duplicate measurements from being stored or processed more than once.

## 6. Summary

RabbitMQ was selected because the platform requires independent asynchronous processing of sensor measurements by Storage and Alert services.

The combination of RabbitMQ, transactional outbox, and idempotent consumers is intended to improve reliability and support the target ingestion workload of 200 messages per second.