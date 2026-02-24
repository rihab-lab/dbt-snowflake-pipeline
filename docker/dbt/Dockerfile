FROM python:3.11-slim
RUN pip install --no-cache-dir dbt-core dbt-snowflake==1.8.*
WORKDIR /app
COPY dbt /app/dbt
COPY docker/dbt/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]