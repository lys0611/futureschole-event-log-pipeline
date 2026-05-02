FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1

WORKDIR /app

RUN pip install --no-cache-dir requests pyyaml

COPY Lab01/traffic_generator /app/Lab01/traffic_generator
COPY Lab02/pubsub/traffic_generator.py /app/Lab02/pubsub/traffic_generator.py

WORKDIR /app/Lab02/pubsub

CMD ["python", "traffic_generator.py", "--mode", "continuous"]
