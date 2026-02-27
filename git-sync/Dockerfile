# syntax=docker/dockerfile:1

# Lean Alpine image pre-loaded with the tools required by the git-sync script.
# The container runs as root so the script can manage SSH key permissions and
# fall back to apk if a package is somehow missing at runtime.
FROM alpine:latest

# Pre-install every package the sync script needs.
# The script has its own apk fallback, but pre-installing avoids the need for
# outbound package-index fetches at runtime.
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache \
        git \
        openssh-client \
        rsync \
        ca-certificates

# Create the directory layout expected by the sync script so volume mounts are
# optional; users can also populate these paths at runtime.
RUN mkdir -p /data/.ssh /data/repo-sync /secrets/ssh

# Bake in the git-sync helper script at a well-known, executable path.
COPY docker-entrypoint.sh /usr/local/bin/git-sync.sh
RUN chmod +x /usr/local/bin/git-sync.sh

# Default to an interactive shell.
# Run the sync script explicitly:  docker run <image> /usr/local/bin/git-sync.sh
# Or mount and run your own script: docker run <image> /scripts/my-sync.sh
CMD ["/bin/sh"]
