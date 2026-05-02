FROM confluentinc/cp-kafka-connect-base:7.5.3

USER root

RUN confluent-hub install --no-prompt confluentinc/kafka-connect-s3:latest \
    && curl -fsSL https://repo1.maven.org/maven2/io/debezium/debezium-connector-mysql/3.0.2.Final/debezium-connector-mysql-3.0.2.Final-plugin.tar.gz -o /tmp/debezium-mysql.tgz \
    && tar -xzf /tmp/debezium-mysql.tgz -C /usr/share/confluent-hub-components \
    && rm -f /tmp/debezium-mysql.tgz

USER appuser
