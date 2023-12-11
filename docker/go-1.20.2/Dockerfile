FROM mysteriumnetwork/xgo:base

# Configure the root Go distribution and bootstrap based on it
ENV GO_VERSION 1202

RUN \
  export ROOT_DIST=https://go.dev/dl/go1.20.2.linux-amd64.tar.gz && \
  export ROOT_DIST_SHA=4eaea32f59cde4dc635fbc42161031d13e1c780b87097f4b4234cfce671f1768 && \
  \
$BOOTSTRAP_PURE

RUN git config --global --add safe.directory /source
