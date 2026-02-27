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

# Fetch and install OpenCode via the official installer
RUN curl -fsSL https://opencode.ai/install | bash

# ---- Stage 2: Runtime ----
# Lean final image: node:alpine + python3 + bash only.
# Build tools (curl, tar, py3-pip) are intentionally omitted.
FROM node:alpine AS runtime

# Runtime system dependencies only
RUN --mount=type=cache,target=/var/cache/apk \
    apk update && \
    apk add python3 bash

# Copy self-contained uv/uvx binaries from the builder stage
COPY --from=builder /usr/bin/uv /usr/bin/uv
COPY --from=builder /usr/bin/uvx /usr/bin/uvx

# Copy the OpenCode binary from the builder stage
COPY --from=builder /root/.opencode/ /root/.opencode/

# Make opencode available on PATH for all processes.
# NOTE: The OpenCode installer writes to $HOME (~root), so this image
# is intentionally designed to run as the root user (Docker's default).
ENV PATH="/root/.opencode/bin:$PATH"

# Create persistent volume mount points
RUN mkdir -p /config /data/sessions /data/snapshots /data/log /projects /mcp

# --- Layers ordered from least- to most-frequently-changed ---

# Entrypoint script (changes rarely)
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Default config (most likely to be tweaked between builds)
COPY config/opencode.json* /config/
RUN if [ -f /config/opencode.jsonc ]; then \
        mv /config/opencode.jsonc /config/opencode.json; \
    fi

EXPOSE 4096

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["web"]
