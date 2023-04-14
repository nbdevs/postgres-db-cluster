#!/bin/sh 
#adapted from #adapted from https://gitlab.com/aztek-io/oss/containers/pgbouncer-container/-/blob/master/Dockerfile LABEL maintainer "robert@aztek.io"

set -e

PG_CONFIG_DIR=/etc/pgbouncer

invoke_main(){
    check_variables
    create_config
    create_config_users
    start_app
}

check_variables(){
    test -n "$DATABASES_HOST" ||
    test -n "$DATABASES" ||
        error "One of either the databases_host or databases environment variables is required to be set."
}

error(){
    MESSAGE="$1"
    EXIT="${2:-1}"

    echo "$MESSAGE"
    exit "$EXIT"
}

# setting databases connection settings for the reuqired configs that pgbouncer should sit infront of {primary/secondary servers}
create_databases_config(){
  if [ -n "$DATABASES" ] ; then
    echo "$DATABASES" | tr , '\n'
  else
    cat << EOF

${DATABASES_CLIENT_SIDE_DBNAME:-*} = host = $DATABASES_HOST \
port = ${DATABASES_PORT:-5432} \
dbname = ${DATABASES_DBNAME:-$POSTGRES_DB} \
auth_user = pgbouncer \
client_encoding = ${DATABASES_CLIENT_ENCODING:-$DATABASES_CLIENT_ENCODING} \
timezone = ${DATABASES_TIMEZONE:-$DATABASES_TIMEZONE}${nl} 
EOF
  fi
}

#creating config for pgbouncer.ini file, variables loaded from .env file 
create_config(){
    echo "Creating pgbouncer config in ${PG_CONFIG_DIR}"

    nl="$(printf '%b_' '\n')";
    nl="${nl%_}"

    cat > ${PG_CONFIG_DIR}/pgbouncer.ini << EOF
#pgbouncer.ini

[databases]
$(create_databases_config)

[users]
pgbouncer=pool_mode=${DATABASES_POOL_MODE:-$PGBOUNCER_POOL_MODE} ${DATABASES_MAX_CONN:-max_user_connections=25}

[pgbouncer]
default_pool_size = ${DATABASES_POOL_SIZE:-$PGBOUNCER_DEFAULT_POOL_SIZE}${nl}\
max_db_connections = ${DATABASES_MAX_DB_CONNECTIONS:-$PGBOUNCER_MAX_DB_CONNECTIONS}${nl}\
logfile = ${PGBOUNCER_LOGFILE:-$PGBOUNCER_LOGFILE}${nl}\
pidfile = ${PGBOUNCER_PIDFILE:-$PGBOUNCER_PIDFILE}${nl}\
listen_addr = ${PGBOUNCER_LISTEN_ADDR:-$PGBOUNCER_BIND_ADDRESS}${nl}\
listen_port = ${PGBOUNCER_LISTEN_PORT:-$PGBOUNCER_LISTEN_PORT}${nl}\
unix_socket_dir = ${PGBOUNCER_UNIX_SOCKET_DIR:-$PGBOUNCER_UNIX_SOCKET_DIR}${nl}\
unix_socket_mode = ${PGBOUNCER_UNIX_SOCKET_MODE:-$PGBOUNCER_UNIX_SOCKET_MODE}${nl}\
unix_socket_group = ${PGBOUNCER_UNIX_SOCKET_GROUP:-$PGBOUNCER_UNIX_SOCKET_GROUP}${nl}\
auth_file = ${PGBOUNCER_AUTH_FILE:-$PGBOUNCER_AUTH_FILE}${nl}\
auth_type = ${PGBOUNCER_AUTH_TYPE:-md5}${nl}\
user = postgres ${nl}\
auth_query = ${PGBOUNCER_AUTH_QUERY:-$PGBOUNCER_AUTH_QUERY}${nl}\
pool_mode = ${PGBOUNCER_POOL_MODE:-$PGBOUNCER_POOL_MODE}${nl}\
max_client_conn = ${PGBOUNCER_MAX_CLIENT_CONN:-$PGBOUNCER_MAX_CLIENT_CONN}${nl}\
ignore_startup_parameters = ${PGBOUNCER_IGNORE_STARTUP:-$PGBOUNCER_IGNORE_STARTUP}${nl}\
default_pool_size = ${PGBOUNCER_DEFAULT_POOL_SIZE:-$PGBOUNCER_DEFAULT_POOL_SIZE}${nl}\
min_pool_size = ${PGBOUNCER_MIN_POOL_SIZE:-$PGBOUNCER_MIN_POOL_SIZE}${nl}\
max_db_connections = ${PGBOUNCER_MAX_DB_CONNECTIONS:-$PGBOUNCER_MAX_DB_CONNECTIONS}${nl}\
max_user_connections = ${PGBOUNCER_MAX_USER_CONNECTIONS:-$PGBOUNCER_MAX_USER_CONNECTIONS}${nl}\
application_name_add_host = ${PGBOUNCER_APPLICATION_NAME_ADD_HOST:-$PGBOUNCER_APPLICATION_NAME_ADD_HOST}${nl}\
server_reset_query = ${SERVER_RESET:-$SERVER_RESET}${nl}\
query_wait_timeout = ${QUERY_WAIT_TIMEOUT:-$PGBOUNCER_QUERY_WAIT_TIMEOUT}${nl}

# Log settings
syslog = ${PGBOUNCER_SYSLOG:-$PGBOUNCER_SYSLOG}${nl}\
syslog_ident = ${PGBOUNCER_SYSLOG_IDENT:-$PGBOUNCER_SYSLOG_IDENT}${nl}\
syslog_facility = ${PGBOUNCER_SYSLOG_FACILITY:-$PGBOUNCER_SYSLOG_FACILITY}${nl}\
log_connections = ${PGBOUNCER_LOG_CONNECTIONS:-$PGBOUNCER_LOG_CONNECTIONS}${nl}\
log_disconnections = ${PGBOUNCER_LOG_DISCONNECTIONS:-$PGBOUNCER_LOG_DISCONNECTIONS}${nl}\
log_pooler_errors = ${PGBOUNCER_LOG_POOLER_ERRORS:-$PGBOUNCER_LOG_POOLER_ERRORS}${nl}\
stats_period = ${PGBOUNCER_STATS_PERIOD:-$PGBOUNCER_STATS_PERIOD}${nl}\
admin_users = ${PGBOUNCER_ADMIN_USERS:-dba, postgres}${nl}\
stats_users = ${PGBOUNCER_STATS_USERS:-postgres, dba}${nl}
EOF

    if [ -z "$QUIET" ]; then
        cat ${PG_CONFIG_DIR}/pgbouncer.ini
    fi
}
# creating users for userlist.txt file 
create_config_users(){
    echo "Now creating pgbouncer user list in ${PG_CONFIG_DIR}"

    nl="$(printf '%b_' '\n')";
    nl="${nl%_}"

    cat > ${PG_CONFIG_DIR}/userlist.txt << EOF
"${pgbouncer:-$pgbouncer}" "${pgbouncerpass:-$pgbouncerpass}"${nl}
EOF

    if [ -z "$QUIET" ]; then
        cat ${PG_CONFIG_DIR}/userlist.txt
    fi
}
#starting pgbouncer with the user as postgres with the ini file location specified within the current directory
start_app(){
    echo "Starting pgbouncer."
    exec /opt/pgbouncer/pgbouncer ${QUIET:+-q} -u postgres ${PG_CONFIG_DIR}/pgbouncer.ini 
}

invoke_main
