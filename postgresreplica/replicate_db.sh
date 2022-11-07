#!/bin/bash

#if file doesn't exist and is not a socket 
if [ ! -s "$PGDATA/PG_VERSION" ]; then

echo "*:*:*:$PG_REP_USER:$PG_REP_PASSWORD" > ~/.pgpass #enables password to be accessible by postgres user after root execution run

chmod 0600 ~/.pgpass # required these permissions for file not to be ignored

set -e # on error exit shell

#creating base backup of primary server for slave server with replication user AND require the password for authentication
pg_basebackup -h ${PG_MAS_HOST} -D ${PGDATA} -Fp -R -X stream -P -S replication_slot_dwdev -v -U ${PG_REP_USER} -W

# alter the connection parameters in the config file for slave db to connect to master
cat > ${PGDATA}/postgresql.conf <<EOF
primary_conninfo = 'host=$PG_MAS_HOST port=$PG_MAS_PORT user=$PG_REP_USER password=$PG_REP_PASSWORD'
promote_trigger_file = '/tmp/postgresql.trigger.5432'
EOF

# grant postgres super user owner permissions in all subdirectories
chown postgres. ${PGDATA} -R
#grant file permissions in all subdirectories
chmod 700 ${PGDATA} -R

fi 

sed -i 's/wal_level = hot_standby/wal_level = replica/g' ${PGDATA}/postgresql.conf

#drop down from root to run postgres server as postgres "su-exec external package provides functionality for this"
exec su-exec postgres postgres "$@"
