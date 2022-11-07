FROM postgres:14.5-alpine

LABEL maintainer="Nicholas Bojor" \
      version="2.3.1" \
      description="Replica database of 3 node cluster"

# install package dependencies 
RUN apk add --no-cache bash su-exec

COPY --chown=postgres ["./replicate_db.sh", "/docker-entrypoint.sh"]

RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
