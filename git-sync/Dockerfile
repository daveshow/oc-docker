# syntax=docker/dockerfile:1

# Lean Alpine image pre-loaded with the tools required by the git-sync script.
FROM alpine:latest

# UID/GID that matches the Kubernetes securityContext (runAsUser/runAsGroup: 10001).
ARG UID=10001
ARG GID=10001

# Pre-install every package the sync script needs.
# The script has its own apk fallback, but pre-installing avoids the need for
# outbound package-index fetches at runtime.
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache \
        git \
        openssh-client \
        rsync \
        ca-certificates

# Create a non-root user/group matching the Kubernetes securityContext.
RUN addgroup -g ${GID} gitsync && \
    adduser -D -u ${UID} -G gitsync -h /home/gitsync gitsync

# Create the directory layout expected by the sync script and give the runtime
# user ownership so volume mounts are optional.
RUN mkdir -p /data/.ssh /data/repo-sync /secrets/ssh && \
    chown -R ${UID}:${GID} /data /secrets

# Redirect HOME to /data/home (the PVC path) so that git global config,
# ssh-keygen, and any other $HOME writes land on the writable PVC rather
# than the read-only root filesystem.
ENV HOME=/data/home

# Bake in the git-sync helper script at a well-known, executable path.
COPY docker-entrypoint.sh /usr/local/bin/git-sync.sh
RUN chmod +x /usr/local/bin/git-sync.sh

USER ${UID}

# Run the sync script once on start, then repeat every SYNC_INTERVAL seconds
# (default: 300).  No ENTRYPOINT — users can override CMD freely.
CMD ["sh", "-c", "/usr/local/bin/git-sync.sh; while true; do sleep \"${SYNC_INTERVAL:-300}\"; /usr/local/bin/git-sync.sh; done"]
