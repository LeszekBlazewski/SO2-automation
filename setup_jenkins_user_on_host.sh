#!/bin/bash

set -eu pipefail

# Creates jenkins user and adds him to docker group on host system in order
# to allow jenkins spawning sibling containers in his jobs

username="jenkins"

# Create jenkins user if he does not exist already
if ! id "$username" &> /dev/null; then
    sudo useradd jenkins
fi

# Add proper docker permissions for jenkins user
if ! id -nG "$username" | grep -qw docker; then
    sudo usermod -aG docker jenkins
fi

# Save jenkins UID and docker group GID to .env
jenkins_uid=$(id -u jenkins)
docker_gid=$(cut -d: -f3 < <(getent group docker))

sed -i "/^HOST_UID/s/=.*$/=$jenkins_uid/" .env
sed -i "/^HOST_GID/s/=.*$/=$docker_gid/" .env