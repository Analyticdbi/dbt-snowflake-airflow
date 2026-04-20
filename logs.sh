#!/bin/bash
echo "========================================="
echo "  LOGS - dbt-snowflake-airflow"
echo "========================================="

echo ""
echo "📋 STATUS DOS CONTAINERS:"
docker compose -f ~/dbt-snowflake-airflow/docker-compose.yml ps

echo ""
echo "📋 ÚLTIMO LOG - run_transformn:"
LAST_RUN=$(ls -t ~/airflow-logs/dag_id=dbt-snowflake-process/ 2>/dev/null | head -1)
cat ~/airflow-logs/dag_id=dbt-snowflake-process/$LAST_RUN/task_id=run_transformn/attempt=1.log 2>/dev/null | tail -15

echo ""
echo "📋 ÚLTIMO LOG - run_analysis:"
cat ~/airflow-logs/dag_id=dbt-snowflake-process/$LAST_RUN/task_id=run_analysis/attempt=1.log 2>/dev/null | tail -15
