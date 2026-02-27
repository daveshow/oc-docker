#!/usr/bin/env sh
# git-sync entrypoint — thin wrapper that configures SSH (when a key is
# mounted) and then executes whatever command the user provides.
# Mount your own sync scripts and invoke them via CMD or `docker run`.
set -e

# If a private SSH key is present, configure git to use it together with
# the pre-populated known_hosts so scripts don't have to handle this setup.
GIT_SSH_KEY_PATH="${GIT_SSH_KEY_PATH:-/data/ssh/id_rsa}"
if [ -f "${GIT_SSH_KEY_PATH}" ]; then
    export GIT_SSH_COMMAND="ssh -i ${GIT_SSH_KEY_PATH} -o StrictHostKeyChecking=yes -o UserKnownHostsFile=/etc/ssh/ssh_known_hosts"
fi

exec "$@"
