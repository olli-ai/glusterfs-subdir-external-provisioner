FROM golang as build-stage
WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY cmd/ ./cmd/
RUN go build -ldflags '-extldflags "-static"' -o ./glusterfs-subdir-external-provisioner ./cmd/glusterfs-subdir-external-provisioner

FROM alpine as production-stage
LABEL MAINTAINER="Aurelien Lambert <aure@olli-ai.com>"

RUN apk --no-cache upgrade && \
    mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2
COPY --from=build-stage /app/glusterfs-subdir-external-provisioner /glusterfs-subdir-external-provisioner
CMD ["/glusterfs-subdir-external-provisioner"]
