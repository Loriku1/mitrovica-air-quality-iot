# Service Level Objectives (SLO)

## 1. Purpose

This document defines the measurable Service Level Objectives (SLOs) for the Mitrovica Air Quality IoT Platform.

The objectives focus on ingestion throughput, measurement durability, alert delivery latency, and platform availability.

The purpose is to ensure that the platform can reliably process sensor measurements and notify operators about dangerous air pollution levels.

## 2. System Workload

The platform is designed to support the following workload:

- 1,000 IoT sensors.
- One measurement every 5 seconds per sensor.
- 200 incoming measurement messages per second.
- Each measurement message contains PM2.5 and PM10 values.
- Raw measurement retention: 7 days.
- One-minute aggregate retention: 90 days.

The target workload is calculated as:

1,000 sensors / 5 seconds = 200 messages per second.

## 3. SLO 1 - Alert Delivery Latency

**Objective:** Pollution alerts must be generated and persisted within 10 seconds.

| Metric | Target |
|---|---|
| Alert delivery latency | ≤ 10 seconds |
| Percentile | p95 |
| Measurement window | 30 minutes |
| Priority | Critical |

### Measurement Method

Alert delivery latency is measured from the moment a measurement is accepted by the Ingestion Service until the corresponding alert is persisted and available through the Alert Service API.

The measurement process will use:

- Timestamped measurement events.
- Distributed tracing with OpenTelemetry.
- Alert processing timestamps.
- Prometheus latency metrics.

The p95 latency must remain at or below 10 seconds during the measurement window.

## 4. SLO 2 - Ingestion Throughput and Durability

**Objective:** The platform must sustain 200 measurement messages per second without losing any accepted measurements.

| Metric | Target |
|---|---|
| Ingestion throughput | 200 messages/second |
| Test duration | 30 minutes |
| Accepted measurement loss | 0 |
| Priority | Critical |

### Measurement Method

A load-testing tool will simulate 1,000 sensors sending one measurement every 5 seconds.

Each measurement will contain a unique identifier.

The test will:

1. Generate 200 measurement messages per second.
2. Submit measurements to the Ingestion Service.
3. Record all acknowledged measurement identifiers.
4. Verify that accepted measurements are durably stored and processed.
5. Compare submitted and processed unique identifiers after the queues have drained.

A measurement is considered accepted only after its database transaction, including the transactional outbox record, has been successfully committed.

The target is zero lost accepted measurements during the test.

## 5. SLO 3 - Platform API Availability

**Objective:** The main platform APIs should remain available for monitoring and data access.

| Metric | Target |
|---|---|
| API availability | ≥ 99.5% |
| Measurement window | 30 days |
| Health endpoints | `/health` |
| Priority | High |

### Measurement Method

API availability will be measured using periodic HTTP health checks against the three microservices:

- Ingestion Service: port 3101.
- Storage Service: port 3102.
- Alert Service: port 3103.

Prometheus will collect health-check results and calculate service availability over a rolling 30-day period.

Availability is calculated as:

Availability = (Total time - Unavailable time) / Total time × 100

## 6. Data Retention Objectives

The platform defines the following data retention requirements:

| Data Type | Retention Period |
|---|---|
| Raw PM2.5 and PM10 measurements | 7 days |
| One-minute aggregated measurements | 90 days |
| Alert history | 90 days (initial target) |

Retention policies will be implemented in the storage layer.

## 7. Monitoring and Observability

The following tools are planned for measuring and monitoring the SLOs:

- **Prometheus:** Collects metrics and performance indicators.
- **Grafana:** Visualizes throughput, latency, and availability.
- **OpenTelemetry:** Collects traces and latency information across services.
- **RabbitMQ Monitoring:** Tracks queue depth, message delivery, and consumer activity.

## 8. SLO Validation

The SLOs will be validated through:

- Load testing with 1,000 simulated sensors.
- Sustained ingestion testing at 200 messages per second.
- Alert latency testing under normal and high load.
- Verification of accepted measurement durability.
- Periodic API health checks.

All SLO targets must be evaluated using measurable metrics rather than assumptions.

## 9. Current Implementation Status

The SLOs are defined as project targets.

The monitoring infrastructure, load-testing tools, and production measurement mechanisms will be implemented during subsequent development phases.