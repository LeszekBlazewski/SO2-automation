FROM ubuntu

RUN apt-get update && apt-get -y install \
    wget \
    curl \
    shellcheck && \
    wget https://raw.githubusercontent.com/torokmark/assert.sh/master/assert.sh