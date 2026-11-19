# Komunikimi · Cilësia e ajrit në Mitrovicë (IoT)

Broker-i: **RabbitMQ**. Thirrjet sinkrone: HTTP me timeout. Ngjarjet: asinkron, të paktën një herë (at-least-once).

## Lidhjet

| Nga | Te | Lloji | Çka dërgohet | Timeout | Retry | Kur dështon | Çelësi i idempotencës |
|---|---|---|---|---|---|---|---|
| ingestion-service | storage-service | ngjarje (asinkron) | `measurement.received` | — | 3 | Pas N provave shkon në DLQ | event_id |
| ingestion-service | alert-service | ngjarje (asinkron) | `measurement.received` | — | 3 | Pas N provave shkon në DLQ | event_id |
| alert-service | storage-service | thirrje HTTP (sinkron) | `GET /internal/measurements/latest? sensorId={sensorId}` | 1000 ms | 1 | Përdor kopjen ose cache-in e fundit | — |

## Ngjarjet

| Ngjarja | Prodhuesi | Konsumuesit | Fushat |
|---|---|---|---|
| `measurement.received` | ingestion-service | storage-service | event_id, sensor_id, pm25, pm10, timestamp, location |
| `measurement.received` | ingestion-service | alert-service | event_id, sensor_id, pm25, pm10, timestamp, location |

## Diagrami i sekuencës

sequenceDiagram
    autonumber
    actor U as IoT Sensor
    participant I as ingestion-service
    participant B as RabbitMQ Fanout Exchange
    participant Q1 as storage.measurements
    participant Q2 as alert.measurements
    participant S as storage-service
    participant A as alert-service

    U->>I: POST /measurements (PM2.5, PM10)
    I->>I: Validate measurement
    I->>I: Save measurement + outbox (one transaction)
    I-->>U: HTTP 202 Accepted

    I->>B: Publish measurement.received
    B->>Q1: Route event
    B->>Q2: Route event

    Q1->>S: Deliver measurement.received
    S->>S: Check event_id and process
    S-->>Q1: Acknowledge message

    Q2->>A: Deliver measurement.received
    A->>A: Check event_id and evaluate thresholds
    A-->>Q2: Acknowledge message

    A->>S: GET /internal/measurements/latest?sensorId={sensorId}
    S-->>A: Latest measurement

## Kur bie një shërbim: çka sheh përdoruesi

- **alert-service**: Përdoruesi vazhdon të shohë matjet e cilësisë së ajrit, por nuk merr alarme të reja derisa shërbimi të rikthehet dhe të përpunojë ngjarjet e mbetura në radhë.
- **ingestion-service**: Përdoruesi sheh njoftimin se pranimi i matjeve është përkohësisht i padisponueshëm dhe të dhënat e sensorëve nuk përditësohen.
- **storage-service**: Përdoruesi sheh matjen e fundit të ruajtur dhe një njoftim se ruajtja dhe historiku i matjeve janë përkohësisht të padisponueshëm.

## Outbox dhe idempotenca

- Outbox te: ingestion-service. Të dhënat dhe rreshti i outbox shkruhen në një transaksion; relay-i publikon rreshtat me `published_at IS NULL`.
- Dedup te: storage-service, alert-service. Efekti dhe `event_id` ruhen në një transaksion; ack vetëm pas commit.

```sql
CREATE TABLE outbox (
  id           uuid PRIMARY KEY,
  topic        text NOT NULL,
  payload      jsonb NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now(),
  published_at timestamptz
);
CREATE TABLE processed_events (
  event_id     text PRIMARY KEY,
  processed_at timestamptz NOT NULL DEFAULT now()
);
-- konsumuesi: INSERT INTO processed_events(event_id) VALUES ($1) ON CONFLICT DO NOTHING;
-- 0 rreshta = dublikatë: kalo dhe jep ack.
```
