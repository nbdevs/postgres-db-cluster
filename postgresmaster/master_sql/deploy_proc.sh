#!/bin/bash

set -e

psql -v ON_ERROR_STOP=1 -U $POSTGRES_USER -d $POSTGRES_DB <<-EOSQL
    CALL fps.user_init('$PG_PASS','$PG_REP_PASSWORD','$PGBOUNCER_PASS','$AIRFLOW_PASS');

EOSQL


