FROM ghcr.io/ghcr.io/mlflow/mlflow:v3.8.0
RUN apt-get update \
    && apt-get -y install libpq-dev gcc \
    && pip install psycopg2 \ 
    && pip install azure-identity \
    && pip install azure-storage-blob 
    
EXPOSE 5000
ARG ARTIFACT_ROOT
# CMD ["mlflow", "server", "--default-artifact-root", "wasbs://artifact-store@mlflowcloudstrg.blob.core.windows.net/artifact-store"]
CMD mlflow server --default-artifact-root ${ARTIFACT_ROOT}