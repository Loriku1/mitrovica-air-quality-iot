# ADR-003: PostgreSQL and TimescaleDB for Time-Series Storage

## Status

Accepted

## Date

2026-11-13

## 1. Context

The Mitrovica Air Quality IoT Platform continuously receives PM2.5 and PM10 measurements from distributed IoT sensors.

The expected workload is approximately 200 incoming measurement messages per second.

The platform must store historical sensor measurements and support time-based queries, aggregation, and retention policies.

The storage layer must support:

- Raw measurement retention for 7 days.
- One-minute aggregate retention for 90 days.
- Historical air quality queries.
- Efficient time-based data retrieval.
- Continuous ingestion from multiple sensors.

A traditional relational database could store this information, but time-series workloads require efficient handling of large volumes of timestamped data.

## 2. Decision

We will use PostgreSQL with the TimescaleDB extension for the Storage Service.

TimescaleDB extends PostgreSQL with time-series capabilities.

The Storage Service will own the time-series database.

Measurements will be organized using timestamp-based hypertables.

The storage design will support:

- PM2.5 and PM10 raw measurements.
- Sensor identifiers.
- Measurement timestamps.
- One-minute aggregated measurements.
- Data retention policies.

Raw measurements will be retained for 7 days, while one-minute aggregates will be retained for 90 days.

## 3. Alternatives Considered

### Standard PostgreSQL

Advantages:
- Reliable relational database.
- SQL support.
- Strong consistency.
- Familiar development environment.

Disadvantages:
- Requires additional configuration and implementation for large time-series workloads.
- Does not provide TimescaleDB-specific time-series features.

### InfluxDB

Advantages:
- Designed specifically for time-series data.
- Efficient time-series ingestion and querying.
- Built-in retention and aggregation capabilities.

Disadvantages:
- Introduces a separate database technology.
- Requires a different query and data access model.
- Would reduce the consistency of the platform's database technology choices.

### MongoDB

Advantages:
- Flexible document model.
- Supports time-series collections.
- Familiar JavaScript ecosystem.

Disadvantages:
- The project requires structured time-based queries and relational capabilities.
- PostgreSQL provides a strong SQL foundation for the planned historical queries and reporting.

## 4. Consequences

Positive consequences:

- Efficient storage and retrieval of timestamped measurements.
- SQL support for historical queries and reporting.
- Time-series hypertables support large measurement volumes.
- Retention policies help control database growth.
- Continuous aggregates can support one-minute measurement summaries.

Negative consequences:

- TimescaleDB introduces additional database configuration.
- Database performance must be tested under the expected ingestion workload.
- Retention and aggregation policies require careful configuration.
- The Storage Service becomes dependent on PostgreSQL and TimescaleDB.

## 5. Data Ownership

The Storage Service owns:

- Raw PM2.5 measurements.
- Raw PM10 measurements.
- One-minute aggregated measurements.
- Measurement timestamps and sensor references.
- Time-series retention policies.

Other services must access historical measurement data through the Storage Service API rather than accessing its database directly.

## 6. Summary

PostgreSQL with TimescaleDB was selected because the platform requires continuous time-series ingestion, historical queries, aggregation, and data retention.

This choice provides PostgreSQL reliability and SQL capabilities together with specialized time-series functionality.