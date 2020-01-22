# xgo
Go CGO cross compiler in docker which is inspired by https://github.com/karalabe/xgo and https://github.com/techknowlogick/xgo but is much simpler
and only contains docker files with no xgo command.

### Usage

```
docker run --rm \
    -v "$PWD"/build:/build \
    -v "$GOPATH"/xgo-cache:/deps-cache:ro \
    -v "$PWD":/source \
    -e OUT=binary_name \
    -e FLAG_V=false \
    -e FLAG_X=false \
    -e FLAG_RACE=false \
    -e FLAG_LDFLAGS="-w -s" \
    -e FLAG_BUILDMODE=default \
    -e TARGETS="linux/amd64,darwin/amd64,windows/amd64" \
    mysteriumnetwork/xgo:1.13.6 ./cmd/path/to/entrypoint
```

Also see and run ./test.sh to build test examples.

### Building image

If you make changes in docker/base you need to rebuild base image.

```
docker build -t mysteriumnetwork/xgo:base -f ./docker/base/Dockerfile ./docker/base
docker push mysteriumnetwork/xgo:base
```

If you add new go version only when build and push.

Build new image.
```
docker build -t mysteriumnetwork/xgo:1.13.6 -f ./docker/go-1.13.6/Dockerfile .
```

Update and run tests.
```
./test.sh
```

Push image
```
docker push mysteriumnetwork/xgo:1.13.6
```