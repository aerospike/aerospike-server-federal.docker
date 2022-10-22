#
# Aerospike Server Enterprise Edition for United States Federal Dockerfile
#
# http://github.com/aerospike/aerospike-server-federal.docker
#


FROM debian:bullseye-slim

ARG DEBUG=false

ARG AEROSPIKE_VERSION=6.1.0.3
ARG AEROSPIKE_EDITION=federal
ARG AEROSPIKE_SHA256=5ce50825e02cfcb04030206230779d7f75daf830d484e29d8f8e50749566798d

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install Aerospike Server and Tools
COPY scripts/bootstrap.sh /bootstrap.sh
RUN ./bootstrap.sh && rm bootstrap.sh

# Add the Aerospike configuration specific to this dockerfile
COPY aerospike.template.conf /etc/aerospike/aerospike.template.conf

# Mount the Aerospike data directory
# VOLUME ["/opt/aerospike/data"]
# Mount the Aerospike config directory
# VOLUME ["/etc/aerospike/"]

# Expose Aerospike ports
#
#   3000 – service port, for client connections
#   3001 – fabric port, for cluster communication
#   3002 – mesh port, for cluster heartbeat
#
EXPOSE 3000 3001 3002

COPY scripts/entrypoint.sh /entrypoint.sh

# Tini init set to restart ASD on SIGUSR1 and terminate ASD on SIGTERM
ENTRYPOINT ["/usr/bin/as-tini-static", "-r", "SIGUSR1", "-t", "SIGTERM", "--", "/entrypoint.sh"]

# Execute the run script in foreground mode
CMD ["asd"]
