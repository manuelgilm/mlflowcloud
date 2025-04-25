FROM ghcr.io/mlflow/mlflow:v3.0.0rc0
RUN apt-get update \
    && apt-get -y install libpq-dev gcc \
    && pip install psycopg2
EXPOSE 5000
CMD ["mlflow", "server"]