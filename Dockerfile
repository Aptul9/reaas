FROM golang:1.21-alpine AS compilation_stage

ARG PODINFO_VERSION=unknown
ARG BUILD_DATE=unknown
ARG VCS_REF=unknown

WORKDIR /build_source

COPY app/podinfo /build_source

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -a -installsuffix cgo \
    -ldflags "-s -w \
    -X github.com/stefanprodan/podinfo/pkg/version.VERSION=${PODINFO_VERSION} \
    -X github.com/stefanprodan/podinfo/pkg/version.REVISION=${VCS_REF}" \
    -o podinfo_binary \
    ./cmd/podinfo

FROM alpine:3.19

ARG PODINFO_VERSION=unknown
ARG BUILD_DATE=unknown
ARG VCS_REF=unknown

LABEL org.opencontainers.image.source="https://github.com/milo-toptal/podinfo-demo" \
      org.opencontainers.image.title="Podinfo" \
      org.opencontainers.image.description="Go microservice" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.version="${PODINFO_VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}"

RUN apk --no-cache add ca-certificates curl && \
    addgroup -g 1000 podinfo_user && \
    adduser -D -u 1000 -G podinfo_user podinfo_user && \
    mkdir -p /ui && \
    chown -R podinfo_user:podinfo_user /ui

COPY --from=compilation_stage --chown=podinfo_user:podinfo_user /build_source/podinfo_binary /usr/local/bin/podinfo
COPY --from=compilation_stage --chown=podinfo_user:podinfo_user /build_source/ui /ui

USER podinfo_user
WORKDIR /

EXPOSE 9898

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:9898/healthz || exit 1

ENTRYPOINT ["/usr/local/bin/podinfo"]
CMD ["--port=9898", "--level=info", "--ui-path=/ui"]