# syntax=docker/dockerfile:1

# ---- Stage 1: Builder ----
# Installs build-only tools (curl, tar, py3-pip) alongside uv and the
# OpenCode binary.  Nothing from this stage leaks into the runtime image.
FROM node:alpine AS builder

# System packages needed only to fetch/install tools
RUN --mount=type=cache,target=/var/cache/apk \
    apk update && \
    apk add python3 py3-pip curl bash tar

# Install uv (self-contained Rust binary; cached between builds)
RUN --mount=type=cache,target=/root/.cache/pip \
    pip3 install --break-system-packages uv

# Fetch and install OpenCode via the official installer (installs to /root/.opencode/bin)
RUN curl -fsSL https://opencode.ai/install | bash

# Copy the binary to /usr/local/bin so it is accessible to any user
RUN cp /root/.opencode/bin/opencode /usr/local/bin/opencode && \
    chmod 755 /usr/local/bin/opencode

# ---- Stage 2: Runtime ----
# Lean final image: node:alpine + python3 + bash + curl + ripgrep.
# Build tools (tar, py3-pip) are intentionally omitted.
FROM node:alpine AS runtime

# Non-root UID/GID that matches the Kubernetes securityContext
ARG UID=10001
ARG GID=10001

# Runtime system dependencies only
RUN --mount=type=cache,target=/var/cache/apk \
    apk update && \
    apk add python3 bash curl ripgrep

# Copy self-contained uv/uvx binaries from the builder stage
COPY --from=builder /usr/bin/uv /usr/bin/uv
COPY --from=builder /usr/bin/uvx /usr/bin/uvx

# Copy the OpenCode binary into /usr/local/bin (world-readable, no home dependency)
COPY --from=builder /usr/local/bin/opencode /usr/local/bin/opencode

# Create a non-root user/group to match the K8s securityContext
RUN addgroup -g ${GID} opencode && \
    adduser -D -u ${UID} -G opencode -h /home/opencode opencode

# Create persistent volume mount points owned by the runtime user
RUN mkdir -p /config /data/sessions /data/snapshots /data/log /projects /mcp && \
    chown -R ${UID}:${GID} /config /data /projects /mcp

# --- Layers ordered from least- to most-frequently-changed ---

# Entrypoint script (changes rarely)
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Default config (most likely to be tweaked between builds)
COPY config/opencode.json* /config/
RUN if [ -f /config/opencode.jsonc ]; then \
        mv /config/opencode.jsonc /config/opencode.json; \
    fi && \
    chown -R ${UID}:${GID} /config

# Default HOME to /data/home so runtime writes go to the PVC even without
# explicit env overrides. The Kubernetes helm chart also sets HOME=/data/home.
ENV HOME=/data/home

USER ${UID}

EXPOSE 3000

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["web"]
