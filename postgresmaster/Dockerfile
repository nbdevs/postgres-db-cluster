FROM postgres:14.5-alpine

LABEL maintainer="Nicholas Bojor" \
      version="5.0.0" \
      description="Master database of 3 node cluster"

COPY --chown=postgres ./master_conf/custom-postgresql.conf /etc/postgresql/postgresql.conf
COPY --chown=postgres ./master_conf/custom-pg_hba.conf /etc/postgresql/pg_hba.conf

COPY --chown=postgres ["./master_sql", "/docker-entrypoint-initdb.d/"]

