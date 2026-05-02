# Lab01 One-VM Docker Compose Run

This lab now has one default execution model:

```text
traffic-generator service -> api-server service -> mysql service
```

The old default model was:

```text
traffic-generator VM -> ALB public IP -> api-server VM -> mysql
```

The ALB public IP and separate VM requirement are removed from the default run path. Internal traffic uses Docker Compose service names:

```text
traffic-generator -> api-server:8080
api-server        -> mysql:3306
Kafka Connect    -> mysql:3306, kafka:9092, schema-registry:8081
```

The traffic generator and API server remain separate services and containers. The existing traffic-generator FSM/user behavior, Flask routes, MySQL schema, Kafka/Filebeat/Logstash files, and Pub/Sub-related files are preserved as much as possible.

## Legacy Scripts

These scripts are now legacy/reference inputs for the Compose model. Do not run them for the default Compose path:

```text
traffic_generator/tg_vm_init.sh
traffic_generator/tg_full_setup.sh
api_server/api_vm_init.sh
api_server/api_env_setup.sh
api_server/api_full_setup.sh
api_server/setup_db.sh
data_stream_vm/data_stream_vm.init
data_stream_vm/schema_registry_setup.sh
data_stream_vm/mysql_source_connector.sh
kafka/s3_sink_connector.sh
```

Script intent was converted into Compose services and connector JSON:

```text
schema_registry_setup.sh       -> schema-registry service
mysql_source_connector.sh      -> kafka_connect/connectors/mysql-source.json
s3_sink_connector.sh           -> kafka_connect/connectors/mysql-s3-sink.json
data_stream_vm.init            -> Compose service env assumptions
```

The legacy scripts used conflicting Kafka Connect REST ports: MySQL source and MySQL S3 sink used `8084`, while nginx S3 sink used `8083`. Compose resolves this with one Kafka Connect worker on `kafka-connect:8083` and registers multiple connectors into that worker.

The optional nginx log S3 sink is not enabled in Compose yet because the default API container is Gunicorn-only and does not run nginx/filebeat/logstash. Existing log config files remain in the repo.

## Required Files

Before running Compose, these files should exist:

```bash
test -f docker-compose.yml
test -f api_server/Dockerfile
test -f api_server/app.py
test -f traffic_generator/Dockerfile
test -f db/init.sql
test -f db/02-debezium-user.sh
test -f mysql/conf.d/cdc.cnf
test -f kafka_connect/Dockerfile
test -f kafka_connect/connectors/mysql-source.json
test -f kafka_connect/connectors/mysql-s3-sink.json
test -f kafka_connect/register-connectors.sh
test -f .env.example
```

## Basic App Run

The basic app flow does not require S3/Object Storage credentials.

```bash
cd day1/Lab01
docker compose up --build
```

To run in the background:

```bash
docker compose up --build -d
```

## Streaming Run

The stream profile adds:

```text
kafka
schema-registry
kafka-connect
connector-init
```

Create a local `.env` from the committed example and fill in real object storage values:

```bash
cp .env.example .env
```

Required `.env` values for the stream profile:

```text
BUCKET_NAME
AWS_ACCESS_KEY_ID_VALUE
AWS_SECRET_ACCESS_KEY_VALUE
AWS_DEFAULT_REGION_VALUE
AWS_DEFAULT_OUTPUT_VALUE
OBJECT_STORAGE_ENDPOINT
```

`STORE_URL` is included in `.env.example` as a compatibility alias, but the current connector uses `OBJECT_STORAGE_ENDPOINT`.

Start the app plus streaming services:

```bash
docker compose --profile stream up --build
```

If this directory was already run before the Debezium user script existed, recreate the MySQL volume once so `db/02-debezium-user.sh` runs:

```bash
docker compose down -v
docker compose --profile stream up --build
```

## MySQL CDC

MySQL CDC is enabled by `mysql/conf.d/cdc.cnf`:

```text
server-id=184054
log_bin=mysql-bin
binlog_format=ROW
binlog_row_image=FULL
```

`db/02-debezium-user.sh` creates the Debezium user on first MySQL initialization and grants the minimal CDC privileges needed for the connector.

## Validate Basic App

```bash
docker compose up --build
docker compose ps
curl http://localhost:8080/health
docker compose logs --tail=100 traffic-generator
docker compose exec mysql mysql -uapp -papppw shopdb -e "SELECT COUNT(*) FROM api_events;"
```

## Validate Streaming

```bash
docker compose --profile stream up --build
curl http://localhost:8081/subjects
curl http://localhost:8083/connectors
curl http://localhost:8083/connectors/mysql-cdc-shopdb/status
docker compose exec kafka kafka-topics --bootstrap-server kafka:9092 --list
```

Useful extra checks:

```bash
curl http://localhost:8083/connector-plugins
curl http://localhost:8083/connectors/mysql-s3-sink-connector/status
docker compose logs --tail=100 kafka-connect
docker compose logs --tail=100 connector-init
```

Expected CDC topics include names like:

```text
mysql-server.shopdb.api_events
mysql-server.shopdb.users
mysql-server.shopdb.orders
mysql-server.shopdb.cart
```

## Rollback And Cleanup

Stop services without deleting data:

```bash
docker compose --profile stream down
```

Stop services and delete MySQL/Kafka state:

```bash
docker compose --profile stream down -v --remove-orphans
```

Return to the basic app-only path:

```bash
docker compose up --build
```
