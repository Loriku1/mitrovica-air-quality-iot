# ADR-002: RabbitMQ Fanout Exchange and Asynchronous Communication

## Status

Accepted

## Date

2026-11-13

## Last Revised

2026-11-16

## 1. Context

The Mitrovica Air Quality IoT Platform is expected to receive approximately 200 measurement messages per second from 1,000 IoT sensors.

Each incoming measurement must be processed independently by two services:

- Storage Service, which persists measurements and creates aggregates.
- Alert Service, which evaluates pollution thresholds and generates alerts.

Using only synchronous HTTP communication would tightly couple the Ingestion Service to downstream services.

The platform therefore requires reliable asynchronous communication.

## 2. Initial Decision

The initial architecture decision was to use RabbitMQ for asynchronous communication.

The original decision established that Storage Service and Alert Service must independently consume measurement events. However, the exact exchange type and queue topology were not explicitly defined.

## 3. Revised Decision

After reviewing the message distribution requirements, the RabbitMQ topology is now explicitly defined using a Fanout Exchange and two independent durable queues.

The communication flow will be:

1. Ingestion Service validates incoming measurements.
2. Ingestion Service stores the measurement metadata and an event in its transactional outbox.
3. An outbox publisher sends measurement events to the RabbitMQ Fanout Exchange.
4. The Fanout Exchange routes a copy of each event to both bound queues.
5. Storage Service consumes events from the storage.measurements queue and persists measurements.
6. Alert Service consumes events from the alert.measurements queue and evaluates pollution thresholds.

Both queues will be durable, and messages will be persistent.

Consumers will acknowledge messages only after successful processing.

Consumers will implement idempotency to prevent duplicate processing.

## 4. Reason for Revising the Decision

Both Storage Service and Alert Service need to receive every relevant measurement independently.

A shared competing-consumer queue would distribute messages among consumers rather than guarantee that both services receive each event.

The Fanout Exchange provides independent message distribution by routing each published event to every bound queue.

This allows Storage and Alert processing to proceed independently. A temporary outage in one consumer does not prevent the other consumer from processing its own queue.

## 5. Alternatives Considered

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

### RabbitMQ Direct Exchange with a Shared Queue

A shared queue could distribute messages among competing consumers.

Advantages:
- Simple queue configuration.
- Useful for distributing workload among instances of the same service.

Disadvantages:
- Does not guarantee that both independent services receive every measurement.
- Storage and Alert require separate processing of the same event.

### Redis Streams

Redis Streams could be used as an event streaming mechanism.

Advantages:
- Lightweight.
- High performance.
- Supports consumer groups.

Disadvantages:
- Requires additional decisions about persistence and stream management.
- RabbitMQ provides a messaging model that better matches the current project requirements.

## 6. Consequences

Positive consequences:

- Storage and Alert receive independent copies of measurement events.
- Each service can process its queue independently.
- Temporary consumer outages can be handled through durable queues.
- Message buffering helps absorb processing spikes.
- Consumers can be scaled independently.

Negative consequences:

- RabbitMQ introduces another infrastructure component.
- Two queues require additional configuration and monitoring.
- Duplicate message delivery must be handled.
- The transactional outbox pattern adds implementation complexity.
- Message processing and queue growth must be monitored.

## 7. Reliability Considerations

The transactional outbox pattern will be used to reduce the risk of losing accepted measurements between database persistence and message publishing.

The Fanout Exchange will route events to both durable queues.

Messages will be persistent, and consumers will use manual acknowledgements after successful processing.

Idempotency keys will prevent duplicate measurements from being stored or processed more than once.

## 8. Implementation Status

The Fanout Exchange topology is an architectural decision planned for implementation.

RabbitMQ, the exchange, queues, transactional outbox publisher, and consumers have not yet been implemented in the current project skeleton.

## 9. Summary

RabbitMQ was selected for asynchronous communication between services.

The decision was subsequently refined to explicitly use a Fanout Exchange with two independent queues, ensuring that both Storage Service and Alert Service receive each measurement event.

This topology supports independent processing and improves the reliability of the planned IoT data pipeline.
