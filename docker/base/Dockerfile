# Go cross compiler (xgo): Base cross-compilation layer
# Copyright (c) 2014 Péter Szilágyi. All rights reserved.
#
# Released under the MIT license.

FROM ubuntu:20.04

MAINTAINER Péter Szilágyi <peterke@gmail.com>

# Configure the Go environment, since it's not going to change
ENV PATH   /usr/local/go/bin:$PATH
ENV GOPATH /go

# Inject the remote file fetcher and checksum verifier
ADD fetch.sh /fetch.sh
ENV FETCH /fetch.sh
RUN chmod +x $FETCH

# Make sure apt-get is up to date and dependent packages are installed
RUN \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y                                      \
    automake autogen build-essential ca-certificates                                     \
    gcc-9-arm-linux-gnueabi g++-9-arm-linux-gnueabi libc6-dev-armel-cross                \
    gcc-9-arm-linux-gnueabihf g++-9-arm-linux-gnueabihf libc6-dev-armhf-cross            \
    gcc-9-aarch64-linux-gnu g++-9-aarch64-linux-gnu libc6-dev-arm64-cross                \
    gcc-9-mips-linux-gnu g++-9-mips-linux-gnu libc6-dev-mips-cross                       \
    gcc-9-mipsel-linux-gnu g++-9-mipsel-linux-gnu libc6-dev-mipsel-cross                 \
    gcc-9-mips64-linux-gnuabi64 g++-9-mips64-linux-gnuabi64 libc6-dev-mips64-cross       \
    gcc-9-mips64el-linux-gnuabi64 g++-9-mips64el-linux-gnuabi64 libc6-dev-mips64el-cross \
    gcc-9-multilib g++-9-multilib gcc-mingw-w64 g++-mingw-w64 clang llvm-dev             \
    libtool libxml2-dev uuid-dev libssl-dev swig openjdk-8-jdk pkg-config patch          \
    make xz-utils cpio wget zip unzip p7zip git mercurial bzr texinfo help2man cmake     \
    zlib1g-dev                                                                           \
    --no-install-recommends

# Fix any stock package issues
RUN ln -s /usr/include/asm-generic /usr/include/asm

##########################
# Darwin Toolchain build #
##########################

# Configure the container for OSX cross compilation
ENV OSX_SDK_VER 11.3
ENV OSX_SDK MacOSX${OSX_SDK_VER}.sdk
ENV OSX_SDK_PATH https://github.com/phracker/MacOSX-SDKs/releases/download/${OSX_SDK_VER}/$OSX_SDK.tar.xz

# Make libxar known to the ld64 and cctools build
ENV LD_LIBRARY_PATH=/osxcross/target/lib

# Download the osx sdk and build the osx toolchain
RUN $FETCH $OSX_SDK_PATH b9f134a1b89df10a4b680f9d6f81ad5579062dcb

# Actually build the toolchain
RUN \
  git clone https://github.com/tpoechtrager/osxcross.git && \
  cd osxcross && git checkout d904031e7e3faa8a23c21b319a65cc915dac51b3 && cd ../ && \
  mv  $OSX_SDK.tar.xz /osxcross/tarballs/ && \
  OSX_VERSION_MIN=10.10 UNATTENDED=1 LD_LIBRARY_PATH=/osxcross/target/lib /osxcross/build.sh

ENV PATH /osxcross/target/bin:$PATH

# Inject the new Go root distribution downloader and bootstrapper
ADD bootstrap_pure.sh /bootstrap_pure.sh
ENV BOOTSTRAP_PURE /bootstrap_pure.sh
RUN chmod +x $BOOTSTRAP_PURE

# Inject the C dependency cross compiler
ADD build_deps.sh /build_deps.sh
ENV BUILD_DEPS /build_deps.sh
RUN chmod +x $BUILD_DEPS

# Inject the container entry point, the build script
ADD build.sh /build.sh
ENV BUILD /build.sh
RUN chmod +x $BUILD

ENTRYPOINT ["/build.sh"]
