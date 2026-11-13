# Project Risks and Mitigation

## 1. Message Loss During Ingestion

**Description:** Measurements may be lost if the Ingestion Service crashes or the message broker becomes unavailable while processing incoming sensor data.

- **Likelihood:** Medium
- **Impact:** Critical
- **Mitigation:**
  - Use a transactional outbox pattern.
  - Persist accepted measurements before acknowledging them.
  - Use durable RabbitMQ queues and persistent messages.
  - Implement retry mechanisms and dead-letter queues.
  - Monitor rejected and unprocessed messages.

## 2. High Message Volume and Processing Delays

**Description:** The platform must process 200 messages per second from 1,000 sensors. Increased traffic may overload services or delay alert generation.

- **Likelihood:** High
- **Impact:** High
- **Mitigation:**
  - Use asynchronous communication through RabbitMQ.
  - Scale service instances horizontally.
  - Apply backpressure and controlled message consumption.
  - Pre-aggregate measurements at edge gateways.
  - Monitor queue depth and processing latency.

## 3. Alert Delivery Delays

**Description:** High broker queue depth, slow database operations, or unavailable services may prevent alerts from being generated within the 10-second p95 target.

- **Likelihood:** Medium
- **Impact:** Critical
- **Mitigation:**
  - Prioritize alert processing.
  - Monitor end-to-end alert latency.
  - Use independent Alert Service consumers.
  - Configure retries and dead-letter queues.
  - Test alert generation under peak load.

## 4. Sensor Failure or Invalid Measurements

**Description:** Sensors may disconnect, send malformed data, report incorrect timestamps, or provide unrealistic PM2.5 and PM10 values.

- **Likelihood:** High
- **Impact:** Medium
- **Mitigation:**
  - Validate incoming measurement schemas.
  - Reject negative or invalid measurement values.
  - Track sensor availability and last-seen timestamps.
  - Detect abnormal readings.
  - Identify sensors that repeatedly send invalid data.

## 5. Database Failure or Storage Capacity Issues

**Description:** Database outages, excessive write operations, or insufficient storage capacity may affect measurement ingestion and historical queries.

- **Likelihood:** Medium
- **Impact:** High
- **Mitigation:**
  - Use PostgreSQL with TimescaleDB for time-series storage.
  - Configure database backups and recovery procedures.
  - Apply retention policies: 7 days for raw measurements and 90 days for aggregates.
  - Monitor database health, disk usage, and query performance.
  - Test database recovery procedures.

## 6. Duplicate Message Processing

**Description:** RabbitMQ retries or consumer restarts may cause the same measurement event to be processed more than once.

- **Likelihood:** Medium
- **Impact:** Medium
- **Mitigation:**
  - Assign a unique measurement ID to every measurement.
  - Implement idempotent consumers.
  - Enforce unique constraints in the database.
  - Acknowledge messages only after successful processing.

## 7. Unauthorized Access and Data Exposure

**Description:** Exposed service endpoints, compromised credentials, or insecure communication may allow unauthorized access to platform resources.

- **Likelihood:** Medium
- **Impact:** High
- **Mitigation:**
  - Use authentication and authorization for protected APIs.
  - Store secrets outside source code.
  - Apply Kubernetes NetworkPolicies.
  - Use TLS for communication between external clients and services.
  - Scan container images and dependencies for vulnerabilities.

## Risk Management Summary

The highest-priority risks are message loss, processing overload, and delayed alerts because they directly threaten the platform's main reliability objectives.

The mitigation strategies will be implemented progressively and validated through load testing, monitoring, failure simulations, and automated security checks.