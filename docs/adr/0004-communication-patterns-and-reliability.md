# ADR 0004: Communication Patterns and Reliability

Statusi: pranuar · Data: 2026-11-19

## Konteksti
	Sistemi duhet të pranojë rreth 200 matje në sekondë dhe t'i shpërndajë te Storage dhe Alert pa i bllokuar shërbimet. Gjithashtu nevojitet komunikim HTTP për kërkesa që kërkojnë përgjigje të menjëhershme.

## Alternativat
Komunikimi vetëm përmes HTTP. Refuzohet sepse krijon varësi të drejtpërdrejtë ndërmjet shërbimeve dhe mund të shkaktojë bllokim kur një shërbim nuk është i disponueshëm.

## Vendimi
Përdorim HTTP për kërkesat sinkrone dhe RabbitMQ Fanout Exchange për shpërndarjen asinkrone të ngjarjeve. Përdorim dy radhë të pavarura dhe event_id për idempotencë.

## Pasojat
Përfitim: shërbimet janë më të pavarura dhe mund të përpunojnë ngjarjet veçmas. Kosto: nevojiten konfigurimi i broker-it, menaxhimi i radhëve, DLQ, retry dhe deduplikimi. Vendimi mund të rishikohet nëse ngarkesa ose kërkesat e sistemit ndryshojnë ndjeshëm.
