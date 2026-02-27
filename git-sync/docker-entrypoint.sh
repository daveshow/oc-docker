#!/usr/bin/env sh
# git-sync entrypoint — runs as the non-root "gitsync" user.
set -e

# ---------------------------------------------------------------------------
# Environment variable defaults
# ---------------------------------------------------------------------------
GIT_SYNC_REPO="${GIT_SYNC_REPO:-}"
GIT_SYNC_BRANCH="${GIT_SYNC_BRANCH:-main}"
GIT_SYNC_DEST="${GIT_SYNC_DEST:-/data/repo}"
GIT_SYNC_INTERVAL="${GIT_SYNC_INTERVAL:-60}"
GIT_SSH_KEY_PATH="${GIT_SSH_KEY_PATH:-/data/ssh/id_rsa}"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log() { echo "[git-sync] $*"; }

# Configure SSH if a private key is mounted
configure_ssh() {
    if [ -f "${GIT_SSH_KEY_PATH}" ]; then
        export GIT_SSH_COMMAND="ssh -i ${GIT_SSH_KEY_PATH} -o StrictHostKeyChecking=yes -o UserKnownHostsFile=/etc/ssh/ssh_known_hosts"
        log "Using SSH key: ${GIT_SSH_KEY_PATH}"
    fi
}

# Clone or hard-reset a local clone to origin/<branch>
do_sync() {
    if [ -d "${GIT_SYNC_DEST}/.git" ]; then
        log "Fetching latest changes..."
        git -C "${GIT_SYNC_DEST}" fetch --prune origin
        log "Warning: resetting working tree to origin/${GIT_SYNC_BRANCH} — any local changes will be lost."
        git -C "${GIT_SYNC_DEST}" reset --hard "origin/${GIT_SYNC_BRANCH}"
    else
        log "Cloning ${GIT_SYNC_REPO} (branch: ${GIT_SYNC_BRANCH})..."
        git clone \
            --branch "${GIT_SYNC_BRANCH}" \
            --single-branch \
            "${GIT_SYNC_REPO}" \
            "${GIT_SYNC_DEST}"
    fi
    log "Sync complete."
}

# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------
case "${1}" in
    sync)
        if [ -z "${GIT_SYNC_REPO}" ]; then
            echo "Error: GIT_SYNC_REPO is required" >&2
            exit 1
        fi

        configure_ssh

        log "Starting continuous sync every ${GIT_SYNC_INTERVAL}s"
        while true; do
            if do_sync; then
                log "Next sync in ${GIT_SYNC_INTERVAL}s"
            else
                log "Sync failed — retrying in ${GIT_SYNC_INTERVAL}s"
            fi
            sleep "${GIT_SYNC_INTERVAL}"
        done
        ;;
    once)
        if [ -z "${GIT_SYNC_REPO}" ]; then
            echo "Error: GIT_SYNC_REPO is required" >&2
            exit 1
        fi

        configure_ssh
        do_sync
        ;;
    *)
        # Pass-through: run any other command directly
        exec "$@"
        ;;
esac
