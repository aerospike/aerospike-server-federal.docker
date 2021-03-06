#!/bin/bash
set -e

fullVersion="$(curl -sSL 'https://www.aerospike.com/artifacts/aerospike-server-federal/' | grep -E '<a href="[0-9.-]+[-]*.*/"' | sed -r 's!.*<a href="([0-9.-]+[-]*.*)/".*!\1!' | sort -V | tail -1)"

sha256="$(curl -sSL "https://www.aerospike.com/artifacts/aerospike-server-federal/${fullVersion}/aerospike-server-federal-${fullVersion}-debian10.tgz.sha256" | cut -d' ' -f1)"

set -x
sed -ri '
	s/^(ENV AEROSPIKE_VERSION) .*/\1 '"$fullVersion"'/;
	s/^(ENV AEROSPIKE_SHA256) .*/\1 '"$sha256"'/;
' Dockerfile
