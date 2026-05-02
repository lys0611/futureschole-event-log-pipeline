# Lab01 One-VM Docker Compose Run

The old default model was:

```text
traffic-generator VM -> ALB public IP -> api-server VM -> mysql
```

The new default model runs on one VM with Docker Compose:

```text
traffic-generator service -> api-server service -> mysql service
```

The ALB public IP is removed from the default run path. The traffic generator and API server remain separate Docker Compose services and separate containers. The traffic generator calls the API server through Docker Compose service discovery with `API_BASE_URL=api-server:8080`, and the API server connects to MySQL with `MYSQL_HOST=mysql`.

The existing traffic-generator FSM/user behavior, Flask routes, MySQL schema, Kafka/Filebeat/Logstash files, and Pub/Sub-related files are preserved as much as possible. The VM setup scripts remain as legacy/reference scripts.

## Run

Run from this directory:

```bash
cd day1/Lab01
docker compose up --build
```

To reset the MySQL volume and re-run schema initialization:

```bash
docker compose down -v
docker compose up --build
```

## Validate

```bash
docker compose up --build
docker compose ps
docker compose logs traffic-generator
curl http://localhost:8080/health
docker compose exec mysql mysql -uapp -papppw shopdb -e "SELECT COUNT(*) FROM api_events;"
```
