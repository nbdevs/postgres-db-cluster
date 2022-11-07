#adapted from https://gitlab.com/aztek-io/oss/containers/pgbouncer-container/-/blob/master/Dockerfile LABEL maintainer "robert@aztek.io"

FROM alpine:3.9

FROM alpine:3.9 AS build_stage

# hadolint ignore=DL3018
RUN apk --update --no-cache add \
        autoconf \
        autoconf-doc \
        automake \
        c-ares \
        c-ares-dev \
        curl \
        gcc \
        libc-dev \
        libevent \
        libevent-dev \
        libtool \
        make \
        libressl-dev \
        file \
        pkgconf

ARG PGBOUNCER_VERSION=1.17.0

RUN curl -Lso  "/tmp/pgbouncer.tar.gz" "https://pgbouncer.github.io/downloads/files/${PGBOUNCER_VERSION}/pgbouncer-${PGBOUNCER_VERSION}.tar.gz" && \
        file "/tmp/pgbouncer.tar.gz"

WORKDIR /tmp

RUN mkdir /tmp/pgbouncer && \
        tar -zxvf pgbouncer.tar.gz -C /tmp/pgbouncer --strip-components 1

WORKDIR /tmp/pgbouncer

RUN ./configure --prefix=/usr && \
        make

FROM alpine:3.9

# hadolint ignore=DL3018
RUN apk --update --no-cache add \
        libevent \
        libressl \
        ca-certificates \
        c-ares

#creating work directories for sockets and logs
WORKDIR /etc/pgbouncer
WORKDIR /var/log/pgbouncer
WORKDIR /var/run/
WORKDIR /var/run/postgresql
WORKDIR /var/run/pgbouncer

# setting permissions on directories
RUN mkdir -m 740 -p /var/run/
RUN mkdir -m 740 -p /var/run/postgresql
RUN mkdir -m 740 -p /var/run/pgbouncer

# changing owner of directories to postgres user 
RUN chown -R postgres:root \
        /etc/pgbouncer \
        /var/log/pgbouncer \
        /var/run/ \
        /var/run/postgresql \
        /var/run/pgbouncer 

USER postgres

#copying directories/files to destintaion locations 
COPY --from=build_stage --chown=postgres ["/tmp/pgbouncer", "/opt/pgbouncer"]
COPY --chown=postgres ["entrypoint.sh", "/opt/pgbouncer"]
COPY --chown=postgres ["pgbouncer.pid", "/var/run/pgbouncer"]

#setting work directory for entrypoint script to run 
WORKDIR /opt/pgbouncer
ENTRYPOINT ["/opt/pgbouncer/entrypoint.sh"]
