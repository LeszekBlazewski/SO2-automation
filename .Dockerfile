FROM bash

RUN apk update && apk add \
    shellcheck && \
    wget https://raw.githubusercontent.com/torokmark/assert.sh/master/assert.sh

CMD ["bash"]