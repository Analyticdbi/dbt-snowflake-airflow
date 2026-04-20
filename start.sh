#!/bin/bash
echo "🚀 Iniciando ambiente dbt-snowflake-airflow..."
PROJECT=~/dbt-snowflake-airflow
cd $PROJECT

bash $PROJECT/rebuild-dbt.sh
docker rm -f transform analysis 2>/dev/null
docker container prune -f -q
docker compose up -d

echo "⏳ Aguardando Airflow inicializar..."
sleep 15
docker compose ps
echo ""
echo "✅ Airflow em http://localhost:8080 (admin/admin)"
echo "📋 Logs: bash ~/dbt-snowflake-airflow/logs.sh"
