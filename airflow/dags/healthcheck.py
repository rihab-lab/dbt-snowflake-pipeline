from datetime import datetime
from airflow import DAG
from airflow.operators.python import PythonOperator

def ping():
    print("✅ Composer is running. Healthcheck OK.")

with DAG(
    dag_id="healthcheck_composer",
    start_date=datetime(2025, 1, 1),
    schedule=None,
    catchup=False,
    tags=["infra", "healthcheck"],
) as dag:
    PythonOperator(task_id="ping", python_callable=ping)