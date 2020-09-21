#!/bin/bash

set -e

username="jenkins"

# Create jenkins user if he does not exist already
if ! id "$username" &> /dev/null; then
    sudo useradd jenkins
fi

# Add proper docker permissions for jenkins user
sudo usermod -aG docker jenkins

# Save jenkins UID and docker group GID to .env
jenkins_uid=$(id -u jenkins)
docker_gid=$(cut -d: -f3 < <(getent group docker))

sed -i "/^HOST_UID/s/=.*$/=$jenkins_uid/" .env
sed -i "/^HOST_GID/s/=.*$/=$docker_gid/" .env