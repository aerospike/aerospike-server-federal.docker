#
# Aerospike Server Enterprise Edition for United States Federal Dockerfile
#
# http://github.com/aerospike/aerospike-server-federal.docker
#


FROM debian:bullseye-slim

ENV AEROSPIKE_VERSION 6.1.0.2
ENV AEROSPIKE_SHA256 625a4258f87e6b0721cd4629333da867b334e3f23e8c90a955d645d999fa1e57
ENV AS_TINI_SHA256 d1f6826dd70cdd88dde3d5a20d8ed248883a3bc2caba3071c8a3a9b0e0de5940


# Install Aerospike Server and Tools
RUN \
  echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections \
  && apt-get update -y \
  && apt-get install -y --no-install-recommends apt-utils 2>&1 | grep -v "delaying package configuration" \
  && apt-get install -y dumb-init gettext-base iproute2 lua5.2 procps python3 python3-distutils wget \
  && wget https://github.com/aerospike/tini/releases/download/1.0.1/as-tini-static -O /usr/bin/as-tini-static \
  && echo "$AS_TINI_SHA256 /usr/bin/as-tini-static" | sha256sum -c - \
  && chmod +x /usr/bin/as-tini-static \
  && wget "https://artifacts.aerospike.com/aerospike-server-federal/${AEROSPIKE_VERSION}/aerospike-server-federal-${AEROSPIKE_VERSION}-debian11.tgz" --progress=bar:force:noscroll -O aerospike-server.tgz 2>&1 \
  && echo "$AEROSPIKE_SHA256 aerospike-server.tgz" | sha256sum -c - \
  && mkdir aerospike \
  && tar xzf aerospike-server.tgz --strip-components=1 -C aerospike \
  && dpkg -i aerospike/aerospike-server-*.deb \
  && dpkg -i aerospike/aerospike-tools-*.deb \
  && rm -rf aerospike-server.tgz aerospike /var/lib/apt/lists/* \
  && rm -rf /opt/aerospike/lib/java \
  && dpkg -r apt-utils ca-certificates wget \
  && dpkg --purge apt-utils ca-certificates wget 2>&1 \
  && apt-get purge -y \
  && apt-get autoremove -y \
  # Remove symbolic links of aerospike tool binaries
  # Move aerospike tool binaries to /usr/bin/
  # Remove /opt/aerospike/bin
  && find /usr/bin/ -lname '/opt/aerospike/bin/*' -delete \
  && find /opt/aerospike/bin/ -user aerospike -group aerospike -exec chown root:root {} + \
  # Since tools release 7.0.5, asadm has been moved from /opt/aerospike/bin/asadm to /opt/aerospike/bin/asadm/asadm (inside an asadm directory)
  && if [ -d '/opt/aerospike/bin/asadm' ]; \
  then \
  mv /opt/aerospike/bin/asadm /usr/lib/; \
  ln -s /usr/lib/asadm/asadm /usr/bin/asadm; \
    # Since tools release 7.1.1, asinfo has been moved from /opt/aerospike/bin/asinfo to /opt/aerospike/bin/asadm/asinfo (inside an asadm directory)
    if [ -f /usr/lib/asadm/asinfo ]; \
    then \
    ln -s /usr/lib/asadm/asinfo /usr/bin/asinfo; \
    fi \
  fi \
  && mv /opt/aerospike/bin/* /usr/bin/ \
  && rm -rf /opt/aerospike/bin


# Add the Aerospike configuration specific to this dockerfile
COPY aerospike.template.conf /etc/aerospike/aerospike.template.conf
COPY entrypoint.sh /entrypoint.sh

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


# Tini init set to restart ASD on SIGUSR1 and terminate ASD on SIGTERM
ENTRYPOINT ["/usr/bin/as-tini-static", "-r", "SIGUSR1", "-t", "SIGTERM", "--", "/entrypoint.sh"]


# Execute the run script in foreground mode
CMD ["asd"]
