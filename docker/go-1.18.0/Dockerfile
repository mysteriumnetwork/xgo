FROM mysteriumnetwork/xgo:base

# Configure the root Go distribution and bootstrap based on it
ENV GO_VERSION 1180

RUN \
  export ROOT_DIST=https://go.dev/dl/go1.18.linux-amd64.tar.gz && \
  export ROOT_DIST_SHA=e85278e98f57cdb150fe8409e6e5df5343ecb13cebf03a5d5ff12bd55a80264f && \
  \
$BOOTSTRAP_PURE
