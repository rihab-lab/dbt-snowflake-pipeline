#!/usr/bin/env bash
set -euo pipefail

mkdir -p /root/.dbt

cat > /root/.dbt/profiles.yml <<EOF
snowdbt:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: ${SNOWFLAKE_ACCOUNT}
      user: ${SNOWFLAKE_USER}
      password: ${SNOWFLAKE_PASSWORD}
      role: ${SNOWFLAKE_ROLE}
      warehouse: ${SNOWFLAKE_WAREHOUSE}
      database: ${SNOWFLAKE_DATABASE}
      schema: ${SNOWFLAKE_SCHEMA}
      threads: 4
EOF

cd /app/dbt
dbt debug
dbt run