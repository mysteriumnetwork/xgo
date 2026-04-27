# Go cross compiler (xgo): Base cross-compilation layer for Go 1.25+

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
    gcc-9-multilib g++-9-multilib gcc-mingw-w64 g++-mingw-w64 clang-12 llvm-12-dev       \
    libtool libxml2-dev uuid-dev libssl-dev swig openjdk-8-jdk pkg-config patch          \
    make xz-utils cpio wget zip unzip p7zip git mercurial bzr texinfo help2man cmake     \
    zlib1g-dev                                                                           \
    --no-install-recommends

# Fix any stock package issues
RUN ln -s /usr/include/asm-generic /usr/include/asm && \
  ln -sf /usr/bin/clang-12 /usr/local/bin/clang && \
  ln -sf /usr/bin/clang++-12 /usr/local/bin/clang++

##########################
# Darwin Toolchain build #
##########################

# Go 1.25+ references SecTrustCopyCertificateChain from Security.framework,
# which is only present in the macOS 12+ SDKs.
ENV OSX_SDK_VER 12.3
ENV OSX_SDK MacOSX${OSX_SDK_VER}.sdk
ENV OSX_SDK_PATH https://github.com/joseluisq/macosx-sdks/releases/download/${OSX_SDK_VER}/$OSX_SDK.tar.xz
ENV DEFAULT_MACOSX_DEPLOYMENT_TARGET 12.0

# Make libxar known to the ld64 and cctools build
ENV LD_LIBRARY_PATH=/osxcross/target/lib

# Download the osx sdk and build the osx toolchain
RUN $FETCH $OSX_SDK_PATH 3abd261ceb483c44295a6623fdffe5d44fc4ac2c872526576ec5ab5ad0f6e26c

# Actually build the toolchain
RUN \
  git clone https://github.com/tpoechtrager/osxcross.git && \
  cd osxcross && git checkout e6ab3fa7423f9235ce9ed6381d6d3af191b46b59 && cd ../ && \
  mv  $OSX_SDK.tar.xz /osxcross/tarballs/ && \
  OSX_VERSION_MIN=12.0 UNATTENDED=1 LD_LIBRARY_PATH=/osxcross/target/lib /osxcross/build.sh

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
