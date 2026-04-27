FROM mysteriumnetwork/xgo:base-macos12

# Configure the root Go distribution and bootstrap based on it
ENV GO_VERSION 1262

RUN \
  export ROOT_DIST=https://go.dev/dl/go1.26.2.linux-amd64.tar.gz && \
  export ROOT_DIST_SHA=990e6b4bbba816dc3ee129eaeaf4b42f17c2800b88a2166c265ac1a200262282 && \
  \
$BOOTSTRAP_PURE

RUN git config --global --add safe.directory /source
