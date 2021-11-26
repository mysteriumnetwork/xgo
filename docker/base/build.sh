#!/bin/bash
#
# Contains the main cross compiler, that individually sets up each target build
# platform, compiles all the C dependencies, then build the requested executable
# itself.
#
# Usage: build.sh <import path>
#
# Needed environment variables:
#   DEPS           - Optional list of C dependency packages to build
#   ARGS           - Optional arguments to pass to C dependency configure scripts
#   OUT            - Optional output prefix to override the package name
#   FLAG_V         - Optional verbosity flag to set on the Go builder
#   FLAG_X         - Optional flag to print the build progress commands
#   FLAG_RACE      - Optional race flag to set on the Go builder
#   FLAG_TAGS      - Optional tag flag to set on the Go builder
#   FLAG_LDFLAGS   - Optional ldflags flag to set on the Go builder
#   FLAG_BUILDMODE - Optional buildmode flag to set on the Go builder
#   FLAG_TRIMPATH  - Optional trimpath flag to set on the Go builder
#   TARGETS        - Comma separated list of build targets to compile for
#   GO_VERSION     - Bootstrapped version of Go to disable uncupported targets
#   EXT_GOPATH     - GOPATH elements mounted from the host filesystem

# Define a function that figures out the binary extension
function extension {
  if [ "$FLAG_BUILDMODE" == "archive" ] || [ "$FLAG_BUILDMODE" == "c-archive" ]; then
    if [ "$1" == "windows" ]; then
      echo ".lib"
    else
      echo ".a"
    fi
  elif [ "$FLAG_BUILDMODE" == "shared" ] || [ "$FLAG_BUILDMODE" == "c-shared" ]; then
    if [ "$1" == "windows" ]; then
      echo ".dll"
    elif [ "$1" == "darwin" ]; then
      echo ".dylib"
    else
      echo ".so"
    fi
  else
    if [ "$1" == "windows" ]; then
      echo ".exe"
    fi
  fi
}

# Go module builds should assume a local repository
# at mapped to /source containing at least a go.mod file.
if [[ ! -d /source ]]; then
  echo "Go modules are enabled but go.mod was not found in the source folder."
  exit 10
fi
# Change into the repo/source folder
cd /source
echo "Building /source/go.mod..."

# Download all the C dependencies
mkdir /deps
DEPS=($DEPS) && for dep in "${DEPS[@]}"; do
  if [ "${dep##*.}" == "tar" ]; then cat "/deps-cache/`basename $dep`" | tar -C /deps -x; fi
  if [ "${dep##*.}" == "gz" ];  then cat "/deps-cache/`basename $dep`" | tar -C /deps -xz; fi
  if [ "${dep##*.}" == "bz2" ]; then cat "/deps-cache/`basename $dep`" | tar -C /deps -xj; fi
done

DEPS_ARGS=($ARGS)

# Save the contents of the pre-build /usr/local folder for post cleanup
USR_LOCAL_CONTENTS=`ls /usr/local`

# Configure some global build parameters
NAME=`sed -n 's/module\ \(.*\)/\1/p' /source/go.mod`
PACK_RELPATH=$1

if [ "$OUT" != "" ]; then
  NAME=$OUT
fi

if [ "$FLAG_V" == "true" ];    then V=-v; fi
if [ "$FLAG_X" == "true" ];    then X=-x; fi
if [ "$FLAG_RACE" == "true" ]; then R=-race; fi
if [ "$FLAG_TAGS" != "" ];     then T=(--tags "$FLAG_TAGS"); fi
if [ "$FLAG_LDFLAGS" != "" ];  then LD="$FLAG_LDFLAGS"; fi

if [ "$FLAG_BUILDMODE" != "" ] && [ "$FLAG_BUILDMODE" != "default" ]; then BM="--buildmode=$FLAG_BUILDMODE"; fi
if [ "$FLAG_TRIMPATH" == "true" ]; then TP=-trimpath; fi
if [ "$FLAG_MOD" != "" ]; then MOD="--mod=$FLAG_MOD"; fi

# If no build targets were specified, inject a catch all wildcard
if [ "$TARGETS" == "" ]; then
  TARGETS="./."
fi

# Build for each requested platform individually
for TARGET in ${TARGETS//,/ }; do
  # Split the target into platform and architecture
  XGOOS=`echo $TARGET | cut -d '/' -f 1`
  XGOARCH=`echo $TARGET | cut -d '/' -f 2`

  # Check and build for Linux targets
  if ([ $XGOOS == "." ] || [ $XGOOS == "linux" ]) && ([ $XGOARCH == "." ] || [ $XGOARCH == "amd64" ]); then
    echo "Compiling for linux/amd64..."
    HOST=x86_64-linux PREFIX=/usr/local $BUILD_DEPS /deps ${DEPS_ARGS[@]}
    GOOS=linux GOARCH=amd64 CGO_ENABLED=1 go build $V $X $TP $MOD "${T[@]}" --ldflags="$V $LD" $R $BM -o "/build/$NAME-linux-amd64$R`extension linux`" $PACK_RELPATH
  fi
  if ([ $XGOOS == "." ] || [ $XGOOS == "linux" ]) && ([ $XGOARCH == "." ] || [ $XGOARCH == "386" ]); then
    echo "Compiling for linux/386..."
    HOST=i686-linux PREFIX=/usr/local $BUILD_DEPS /deps ${DEPS_ARGS[@]}
    GOOS=linux GOARCH=386 CGO_ENABLED=1 go build $V $X $TP $MOD "${T[@]}" --ldflags="$V $LD" $BM -o "/build/$NAME-linux-386`extension linux`" $PACK_RELPATH
  fi
  if ([ $XGOOS == "." ] || [ $XGOOS == "linux" ]) && ([ $XGOARCH == "." ] || [ $XGOARCH == "arm" ] || [ $XGOARCH == "arm-7" ]); then
    if [ "$GO_VERSION" -lt 150 ]; then
      echo "Go version too low, skipping linux/arm-7..."
    else
      echo "Compiling for linux/arm-7..."
      CC=arm-linux-gnueabihf-gcc-9 CXX=arm-linux-gnueabihf-g++-9 HOST=arm-linux-gnueabihf PREFIX=/usr/arm-linux-gnueabihf CFLAGS="-march=armv7-a -fPIC" CXXFLAGS="-march=armv7-a -fPIC" $BUILD_DEPS /deps ${DEPS_ARGS[@]}
      export PKG_CONFIG_PATH=/usr/arm-linux-gnueabihf/lib/pkgconfig

      CC=arm-linux-gnueabihf-gcc-9 CXX=arm-linux-gnueabihf-g++-9 GOOS=linux GOARCH=arm GOARM=7 CGO_ENABLED=1 CGO_CFLAGS="-march=armv7-a -fPIC" CGO_CXXFLAGS="-march=armv7-a -fPIC" go build $V $X $TP $MOD "${T[@]}" --ldflags="$V $LD" $BM -o "/build/$NAME-linux-arm-7`extension linux`" $PACK_RELPATH
    fi
  fi
  if ([ $XGOOS == "." ] || [ $XGOOS == "linux" ]) && ([ $XGOARCH == "." ] || [ $XGOARCH == "arm64" ]); then
    if [ "$GO_VERSION" -lt 150 ]; then
      echo "Go version too low, skipping linux/arm64..."
    else
      echo "Compiling for linux/arm64..."
      CC=aarch64-linux-gnu-gcc-9 CXX=aarch64-linux-gnu-g++-9 HOST=aarch64-linux-gnu PREFIX=/usr/aarch64-linux-gnu $BUILD_DEPS /deps ${DEPS_ARGS[@]}
      export PKG_CONFIG_PATH=/usr/aarch64-linux-gnu/lib/pkgconfig

      CC=aarch64-linux-gnu-gcc-9 CXX=aarch64-linux-gnu-g++-9 GOOS=linux GOARCH=arm64 CGO_ENABLED=1 go build $V $X $TP $MOD "${T[@]}" --ldflags="$V $LD" $BM -o "/build/$NAME-linux-arm64`extension linux`" $PACK_RELPATH
    fi
  fi
  if ([ $XGOOS == "." ] || [ $XGOOS == "linux" ]) && ([ $XGOARCH == "." ] || [ $XGOARCH == "mips64" ]); then
    if [ "$GO_VERSION" -lt 170 ]; then
      echo "Go version too low, skipping linux/mips64..."
    else
      echo "Compiling for linux/mips64..."
      CC=mips64-linux-gnuabi64-gcc-9 CXX=mips64-linux-gnuabi64-g++-9 HOST=mips64-linux-gnuabi64 PREFIX=/usr/mips64-linux-gnuabi64 $BUILD_DEPS /deps ${DEPS_ARGS[@]}
      export PKG_CONFIG_PATH=/usr/mips64-linux-gnuabi64/lib/pkgconfig

      CC=mips64-linux-gnuabi64-gcc-9 CXX=mips64-linux-gnuabi64-g++-9 GOOS=linux GOARCH=mips64 CGO_ENABLED=1 go build $V $X $TP $MOD "${T[@]}" --ldflags="$V $LD" $BM -o "/build/$NAME-linux-mips64`extension linux`" $PACK_RELPATH
    fi
  fi
  if ([ $XGOOS == "." ] || [ $XGOOS == "linux" ]) && ([ $XGOARCH == "." ] || [ $XGOARCH == "mips64le" ]); then
    if [ "$GO_VERSION" -lt 170 ]; then
      echo "Go version too low, skipping linux/mips64le..."
    else
      echo "Compiling for linux/mips64le..."
      CC=mips64el-linux-gnuabi64-gcc-9 CXX=mips64el-linux-gnuabi64-g++-9 HOST=mips64el-linux-gnuabi64 PREFIX=/usr/mips64el-linux-gnuabi64 $BUILD_DEPS /deps ${DEPS_ARGS[@]}
      export PKG_CONFIG_PATH=/usr/mips64le-linux-gnuabi64/lib/pkgconfig

      CC=mips64el-linux-gnuabi64-gcc-9 CXX=mips64el-linux-gnuabi64-g++-9 GOOS=linux GOARCH=mips64le CGO_ENABLED=1 go build $V $X $TP $MOD "${T[@]}" --ldflags="$V $LD" $BM -o "/build/$NAME-linux-mips64le`extension linux`" $PACK_RELPATH
    fi
  fi
  if ([ $XGOOS == "." ] || [ $XGOOS == "linux" ]) && ([ $XGOARCH == "." ] || [ $XGOARCH == "mips" ]); then
    if [ "$GO_VERSION" -lt 180 ]; then
      echo "Go version too low, skipping linux/mips..."
    else
      echo "Compiling for linux/mips..."
      CC=mips-linux-gnu-gcc-9 CXX=mips-linux-gnu-g++-9 HOST=mips-linux-gnu PREFIX=/usr/mips-linux-gnu $BUILD_DEPS /deps ${DEPS_ARGS[@]}
      export PKG_CONFIG_PATH=/usr/mips-linux-gnu/lib/pkgconfig

      CC=mips-linux-gnu-gcc-9 CXX=mips-linux-gnu-g++-9 GOOS=linux GOARCH=mips CGO_ENABLED=1 go build $V $X $TP $MOD "${T[@]}" --ldflags="$V $LD" $BM -o "/build/$NAME-linux-mips`extension linux`" $PACK_RELPATH
    fi
  fi
  if ([ $XGOOS == "." ] || [ $XGOOS == "linux" ]) && ([ $XGOARCH == "." ] || [ $XGOARCH == "mipsle" ]); then
    if [ "$GO_VERSION" -lt 180 ]; then
      echo "Go version too low, skipping linux/mipsle..."
    else
      echo "Compiling for linux/mipsle..."
      CC=mipsel-linux-gnu-gcc-9 CXX=mipsel-linux-gnu-g++-9 HOST=mipsel-linux-gnu PREFIX=/usr/mipsel-linux-gnu $BUILD_DEPS /deps ${DEPS_ARGS[@]}
      export PKG_CONFIG_PATH=/usr/mipsle-linux-gnu/lib/pkgconfig
      CC=mipsel-linux-gnu-gcc-9 CXX=mipsel-linux-gnu-g++-9 GOOS=linux GOARCH=mipsle CGO_ENABLED=1 go build $V $X $TP $MOD "${T[@]}" --ldflags="$V $LD" $BM -o "/build/$NAME-linux-mipsle`extension linux`" $PACK_RELPATH
    fi
  fi
  # Check and build for Windows targets
  if [ $XGOOS == "." ] || [[ $XGOOS == windows* ]]; then
    # Split the platform version and configure the Windows NT version
    PLATFORM=`echo $XGOOS | cut -d '-' -f 2`
    if [ "$PLATFORM" == "" ] || [ "$PLATFORM" == "." ] || [ "$PLATFORM" == "windows" ]; then
      PLATFORM=4.0 # Windows NT
    fi

    MAJOR=`echo $PLATFORM | cut -d '.' -f 1`
    if [ "${PLATFORM/.}" != "$PLATFORM" ] ; then
      MINOR=`echo $PLATFORM | cut -d '.' -f 2`
    fi
    CGO_NTDEF="-D_WIN32_WINNT=0x`printf "%02d" $MAJOR``printf "%02d" $MINOR`"

    # Build the requested windows binaries
    if [ $XGOARCH == "." ] || [ $XGOARCH == "amd64" ]; then
      echo "Compiling for windows-$PLATFORM/amd64..."
      CC=x86_64-w64-mingw32-gcc-posix CXX=x86_64-w64-mingw32-g++-posix HOST=x86_64-w64-mingw32 PREFIX=/usr/x86_64-w64-mingw32 $BUILD_DEPS /deps ${DEPS_ARGS[@]}
      export PKG_CONFIG_PATH=/usr/x86_64-w64-mingw32/lib/pkgconfig

      CC=x86_64-w64-mingw32-gcc-posix CXX=x86_64-w64-mingw32-g++-posix GOOS=windows GOARCH=amd64 CGO_ENABLED=1 CGO_CFLAGS="$CGO_NTDEF" CGO_CXXFLAGS="$CGO_NTDEF" go build $V $X $TP $MOD "${T[@]}" --ldflags="$V $LD" $R $BM -o "/build/$NAME-windows-$PLATFORM-amd64$R`extension windows`" $PACK_RELPATH
    fi
    if [ $XGOARCH == "." ] || [ $XGOARCH == "386" ]; then
      echo "Compiling for windows-$PLATFORM/386..."
      CC=i686-w64-mingw32-gcc-posix CXX=i686-w64-mingw32-g++-posix HOST=i686-w64-mingw32 PREFIX=/usr/i686-w64-mingw32 $BUILD_DEPS /deps ${DEPS_ARGS[@]}
      export PKG_CONFIG_PATH=/usr/i686-w64-mingw32/lib/pkgconfig

      CC=i686-w64-mingw32-gcc-posix CXX=i686-w64-mingw32-g++-posix GOOS=windows GOARCH=386 CGO_ENABLED=1 CGO_CFLAGS="$CGO_NTDEF" CGO_CXXFLAGS="$CGO_NTDEF" go build $V $X $TP $MOD "${T[@]}" --ldflags="$V $LD" $BM -o "/build/$NAME-windows-$PLATFORM-386`extension windows`" $PACK_RELPATH
    fi
  fi
  # Check and build for OSX targets
  if [ $XGOOS == "." ] || [[ $XGOOS == darwin* ]]; then
    # Split the platform version and configure the deployment target
    PLATFORM=`echo $XGOOS | cut -d '-' -f 2`
    if [ "$PLATFORM" == "" ] || [ "$PLATFORM" == "." ] || [ "$PLATFORM" == "darwin" ]; then
      PLATFORM=10.10 # OS X Yosemite
    fi
    export MACOSX_DEPLOYMENT_TARGET=$PLATFORM

    # Strip symbol table below Go 1.6 to prevent DWARF issues
    LDSTRIP=""
    if [ "$GO_VERSION" -lt 160 ]; then
      LDSTRIP="-s"
    fi
    # Build the requested darwin binaries
    if [ $XGOARCH == "." ] || [ $XGOARCH == "amd64" ]; then
      echo "Compiling for darwin-$PLATFORM/amd64..."
      CC=o64-clang CXX=o64-clang++ HOST=x86_64-apple-darwin14 PREFIX=/usr/local $BUILD_DEPS /deps ${DEPS_ARGS[@]}
      CC=o64-clang CXX=o64-clang++ GOOS=darwin GOARCH=amd64 CGO_ENABLED=1 go build $V $X $TP $MOD "${T[@]}" --ldflags="$LDSTRIP $V $LD" $R $BM -o "/build/$NAME-darwin-$PLATFORM-amd64$R`extension darwin`" $PACK_RELPATH
    fi
    if [ $XGOARCH == "." ] || [ $XGOARCH == "arm64" ]; then
      echo "Compiling for darwin-$PLATFORM/arm64..."
      CC=oa64-clang CXX=oa64-clang++ HOST=aarch64-apple-darwin14 PREFIX=/usr/local $BUILD_DEPS /deps ${DEPS_ARGS[@]}
      CC=oa64-clang CXX=oa64-clang++ GOOS=darwin GOARCH=arm64 CGO_ENABLED=1 go build $V $X $TP $MOD "${T[@]}" --ldflags="$LDSTRIP $V $LD" $R $BM -o "/build/$NAME-darwin-$PLATFORM-arm64$R`extension darwin`" $PACK_RELPATH
    fi
    # Remove any automatically injected deployment target vars
    unset MACOSX_DEPLOYMENT_TARGET
  fi
done

# Clean up any leftovers for subsequent build invocations
echo "Cleaning up build environment..."
rm -rf /deps

for dir in `ls /usr/local`; do
  keep=0

  # Check against original folder contents
  for old in $USR_LOCAL_CONTENTS; do
    if [ "$old" == "$dir" ]; then
      keep=1
    fi
  done
  # Delete anything freshly generated
  if [ "$keep" == "0" ]; then
    rm -rf "/usr/local/$dir"
  fi
done
