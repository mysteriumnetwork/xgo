#!/bin/bash
set -e

# List of comma separated targets.
TARGETS="linux/arm,linux/arm64,linux/amd64,darwin/amd64,darwin/arm64,windows/amd64"

docker run --rm \
    -v "$PWD"/build:/build \
    -v "$GOPATH"/xgo-cache:/deps-cache:ro \
    -v "$PWD":/source \
    -e OUT=embedded_c \
    -e FLAG_V=false \
    -e FLAG_X=false \
    -e FLAG_RACE=false \
    -e FLAG_LDFLAGS="-s -w" \
    -e TARGETS=$TARGETS \
    mysteriumnetwork/xgo:1.17.3 ./tests/embedded_c/.

docker run --rm \
    -v "$PWD"/build:/build \
    -v "$GOPATH"/xgo-cache:/deps-cache:ro \
    -v "$PWD":/source \
    -e OUT=embedded_cpp \
    -e FLAG_V=false \
    -e FLAG_X=false \
    -e FLAG_RACE=false \
    -e FLAG_BUILDMODE=default \
    -e TARGETS=$TARGETS \
    mysteriumnetwork/xgo:1.17.3 ./tests/embedded_cpp/.
