FROM ghcr.io/mlflow/mlflow:v3.6.0
RUN apt-get update \
    && apt-get -y install libpq-dev gcc \
    && pip install psycopg2 \ 
    && pip install azure-identity \
    && pip install azure-storage-blob 
    
EXPOSE 5000
CMD ["mlflow", "server", "--default-artifact-root", "wasbs://artifact-store@mlcloudartifactstore.blob.core.windows.net/artifacts"]