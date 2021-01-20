.PHONY: default install build test lint clean

BINARY ?= glusterfs-subdir-external-provisioner

GOCMD = go
GOLINTCMD = golint
GOFLAGS ?= $(GOFLAGS:)
LDFLAGS =-ldflags '-extldflags "-static"'
RUN ?= "."

default: build

install:
	"$(GOCMD)" mod download

build:
	"$(GOCMD)" build ${GOFLAGS} ${LDFLAGS} -o "${BINARY}" ./cmd/glusterfs-subdir-external-provisioner

test:
	"$(GOCMD)" test -timeout 1800s -v ./cmd/glusterfs-subdir-external-provisioner/... -run "${RUN}"

lint:
	"$(GOLINTCMD)" ./cmd/glusterfs-subdir-external-provisioner/...

clean:
	"$(GOCMD)" clean -i
