FROM golang as build-stage
WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY cmd/ ./cmd/
CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -o glusterfs-subdir-external-provisioner ./cmd/glusterfs-subdir-external-provisioner

FROM alpine as production-stage
COPY --from=build-stage /app/glusterfs-subdir-external-provisioner /glusterfs-subdir-external-provisioner
ENTRYPOINT  ["/glusterfs-subdir-external-provisioner"]
