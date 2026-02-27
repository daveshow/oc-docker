# syntax=docker/dockerfile:1

# ---- Stage 1: setup ----
# Installs build-only tools (openssh-client, ca-certificates, curl) and
# pre-fetches SSH host keys for common git forges so that the runtime
# container never has to make an outbound keyscan on first connect.
# None of the tools added here leak into the final image.
FROM alpine:latest AS setup

RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache \
        openssh-client \
        ca-certificates

# Pre-fetch SSH host keys for common git providers and store them in a
# temporary file that will be copied into the runtime stage.
# Errors are printed to stderr so build logs capture any network issues.
# The build continues even if keyscan partially fails; the runtime image
# will fall back to interactive host-key verification for any missing entries.
RUN mkdir -p /tmp/ssh && \
    { ssh-keyscan -H github.com gitlab.com bitbucket.org > /tmp/ssh/known_hosts_git || \
      echo "Warning: ssh-keyscan encountered errors; known_hosts may be incomplete" >&2; }

# ---- Stage 2: runtime ----
# Lean final image: latest Alpine + only the packages required for
# git-sync operations.  Build tools from Stage 1 are intentionally omitted.
FROM alpine:latest AS runtime

# Non-root UID/GID that matches typical Kubernetes securityContext defaults
ARG UID=10001
ARG GID=10001

# Runtime packages — installed in a single grouped layer to minimise image
# layers and size.  Cache mount avoids re-downloading the apk index on every
# build (Leverage Build Caching / Use Cache Mounts).
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache \
        git \
        openssh-client \
        rsync \
        ca-certificates

# Create a non-root user/group for least-privilege execution
RUN addgroup -g ${GID} gitsync && \
    adduser -D -u ${UID} -G gitsync -h /home/gitsync gitsync

# Create persistent volume mount points owned by the runtime user
RUN mkdir -p /data/repo /data/ssh /data/log && \
    chown -R ${UID}:${GID} /data

# --- Layers ordered from least- to most-frequently-changed ---

# Pre-fetched SSH known_hosts from the setup stage (changes only when
# a forge rotates its host key — very rarely).
COPY --from=setup /tmp/ssh/known_hosts_git /etc/ssh/ssh_known_hosts

# Entrypoint script (changes rarely)
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

USER ${UID}

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["/bin/sh"]
