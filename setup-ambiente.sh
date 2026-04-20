#!/bin/bash
echo "========================================="
echo "  SETUP - dbt-snowflake-airflow"
echo "========================================="

PROJECT=~/dbt-snowflake-airflow
DAG=$PROJECT/dags/docker-dbt-snowflake.py

# ── 1. Retry automático na DAG ─────────────────────────────
echo ""
echo "1️⃣  Configurando retry automático na DAG..."

sed -i 's/from datetime import datetime/from datetime import datetime, timedelta/' $DAG
sed -i 's/"depends_on_past": False,/"depends_on_past": False,\n    "retries": 2,\n    "retry_delay": timedelta(minutes=1),/' $DAG

echo "✅ Retry configurado (2 tentativas, intervalo de 1 minuto)"

# ── 2. Script de logs ──────────────────────────────────────
echo ""
echo "2️⃣  Criando script de logs..."

cat > $PROJECT/logs.sh << 'LOGS'
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
LOGS

chmod +x $PROJECT/logs.sh
echo "✅ Script de logs criado"

# ── 3. Script de rebuild da imagem dbt ────────────────────
echo ""
echo "3️⃣  Criando script de rebuild automático..."

cat > $PROJECT/rebuild-dbt.sh << 'REBUILD'
#!/bin/bash
PROJECT=~/dbt-snowflake-airflow
HASH_FILE=$PROJECT/.dbt_hash
CURRENT_HASH=$(find $PROJECT/src/dbt -type f | sort | xargs md5sum 2>/dev/null | md5sum | cut -d' ' -f1)
SAVED_HASH=$(cat $HASH_FILE 2>/dev/null)

if [ "$CURRENT_HASH" != "$SAVED_HASH" ]; then
    echo "🔄 Mudanças detectadas! Rebuilding imagem dbt-snowflake..."
    docker build -f $PROJECT/Dockerfile.dbt -t dbt-snowflake $PROJECT && \
    echo $CURRENT_HASH > $HASH_FILE && \
    echo "✅ Imagem reconstruída com sucesso!"
else
    echo "✅ Sem mudanças. Imagem dbt-snowflake atualizada."
fi
REBUILD

chmod +x $PROJECT/rebuild-dbt.sh
echo "✅ Script de rebuild criado"

# ── 4. Script de inicialização ────────────────────────────
echo ""
echo "4️⃣  Criando script de inicialização..."

cat > $PROJECT/start.sh << 'START'
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
START

chmod +x $PROJECT/start.sh
echo "✅ Script de inicialização criado"

# ── 5. Auto-start no WSL ──────────────────────────────────
echo ""
echo "5️⃣  Configurando auto-start no WSL..."

if ! grep -q "dbt-snowflake-airflow" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Auto-start dbt-snowflake-airflow" >> ~/.bashrc
    echo "bash ~/dbt-snowflake-airflow/start.sh" >> ~/.bashrc
    echo "✅ Auto-start configurado no .bashrc"
else
    echo "✅ Auto-start já configurado"
fi

# ── Resumo ────────────────────────────────────────────────
echo ""
echo "========================================="
echo "  CONCLUÍDO!"
echo "========================================="
echo ""
echo "Comandos disponíveis:"
echo "  bash ~/dbt-snowflake-airflow/start.sh       → Subir ambiente"
echo "  bash ~/dbt-snowflake-airflow/logs.sh        → Ver logs"
echo "  bash ~/dbt-snowflake-airflow/rebuild-dbt.sh → Rebuild dbt"
echo ""
