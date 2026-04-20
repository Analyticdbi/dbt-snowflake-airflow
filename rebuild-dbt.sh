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
