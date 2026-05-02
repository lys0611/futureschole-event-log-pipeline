#!/bin/sh
set -eu

CONNECT_URL="${CONNECT_URL:-http://kafka-connect:8083}"

required_env="BUCKET_NAME AWS_ACCESS_KEY_ID_VALUE AWS_SECRET_ACCESS_KEY_VALUE AWS_DEFAULT_REGION_VALUE AWS_DEFAULT_OUTPUT_VALUE OBJECT_STORAGE_ENDPOINT"
for var in $required_env; do
  eval "value=\${$var:-}"
  if [ -z "$value" ]; then
    echo "Missing required stream profile env var: $var"
    exit 1
  fi
done

echo "Waiting for Kafka Connect at $CONNECT_URL"
until curl -fsS "$CONNECT_URL/connectors" >/dev/null; do
  sleep 2
done

for connector_file in /connectors/*.json; do
  connector_name="$(sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$connector_file" | head -n 1)"
  if [ -z "$connector_name" ]; then
    echo "Could not determine connector name from $connector_file"
    exit 1
  fi

  if curl -fsS "$CONNECT_URL/connectors/$connector_name" >/dev/null; then
    echo "Connector already exists, skipping: $connector_name"
  else
    echo "Creating connector: $connector_name"
    curl -fsS -X POST \
      -H "Content-Type: application/json" \
      --data-binary "@$connector_file" \
      "$CONNECT_URL/connectors" >/dev/null
  fi
done

echo "Connector registration completed"
