# syntax=docker/dockerfile:1
FROM eclipse-temurin:25-jre

LABEL maintainer="Enes Baki Sirmen"
LABEL org.opencontainers.image.title="Hytale Server"
LABEL org.opencontainers.image.description="Dockerized Hytale Game Server"
LABEL org.opencontainers.image.source="https://github.com/enesbakis/hytale-docker"

# Build arguments
ARG TARGETARCH

# Environment variables
ENV UID=1000 \
    GID=1000 \
    MEMORY=4G \
    INIT_MEMORY="" \
    MAX_MEMORY="" \
    TZ=UTC \
    SERVER_PORT=5520 \
    SERVER_HOST=0.0.0.0 \
    JVM_OPTS="" \
    EXTRA_ARGS="" \
    ENABLE_AOT=false \
    DEBUG=false

# Install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    procps \
    gosu \
    && rm -rf /var/lib/apt/lists/*

# Create hytale user and group (handle existing GID/UID)
RUN groupadd --gid 1000 hytale 2>/dev/null || groupmod -n hytale $(getent group 1000 | cut -d: -f1) || true \
    && useradd --system --shell /bin/false --uid 1000 --gid 1000 --home /data hytale 2>/dev/null || true

# Create directories
RUN mkdir -p /data /scripts /server \
    && chown -R 1000:1000 /data /scripts /server

# Copy scripts
COPY --chmod=755 scripts/ /scripts/

# Working directory
WORKDIR /data

# Expose UDP port for QUIC protocol
EXPOSE 5520/udp

# Volume for persistent data
VOLUME ["/data"]

# Signal for graceful shutdown
STOPSIGNAL SIGTERM

# Healthcheck
HEALTHCHECK --start-period=3m --interval=30s --timeout=10s --retries=3 \
    CMD /scripts/hytale-health.sh

# Entrypoint
ENTRYPOINT ["/scripts/entrypoint.sh"]
