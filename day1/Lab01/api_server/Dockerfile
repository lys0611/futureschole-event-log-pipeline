FROM python:3.11-slim

WORKDIR /app

RUN pip install --no-cache-dir "Flask>=2.2,<2.3" gunicorn mysql-connector-python

COPY api_server/app.py /app/app.py

EXPOSE 8080

CMD ["gunicorn", "--workers", "2", "--threads", "4", "-b", "0.0.0.0:8080", "app:app"]
