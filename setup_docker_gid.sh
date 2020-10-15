#!/bin/bash

set -eu

# Saves docker host docker group GID to file in order to allow jenkins spawning sibling containers

# Save docker group GID to .env
docker_gid=$(cut -d: -f3 < <(getent group docker))
sed -i "/^HOST_GID/s/=.*$/=$docker_gid/" .env