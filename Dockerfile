FROM golang as build-stage
WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY cmd/ ./cmd/
RUN go build -ldflags '-extldflags "-static"' -o ./glusterfs-subdir-external-provisioner ./cmd/glusterfs-subdir-external-provisioner

FROM golang as production-stage
COPY --from=build-stage /app/glusterfs-subdir-external-provisioner /glusterfs-subdir-external-provisioner
CMD ["/glusterfs-subdir-external-provisioner"]
