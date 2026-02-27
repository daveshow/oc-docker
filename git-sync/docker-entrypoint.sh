#!/usr/bin/env sh
# git-sync — clone/sync a git repository and push any local changes.
#
# Required environment variable:
#   REPO   – SSH or HTTPS URL of the remote repository
#
# Optional environment variables:
#   WORKDIR      – directory whose contents are synced into the repo
#                  (default: /data)
#   GITDIR       – local clone path (default: /data/repo-sync)
#   SSH_KEY_PATH – path where the SSH key is stored inside the container
#                  (default: /data/.ssh/id_rsa)
#   SECRETPATH     – path where an externally-mounted SSH key can be found
#                    (default: /secrets/ssh/id_rsa)
#   GIT_USER_EMAIL – git commit author email  (default: opencode@daveshow.local)
#   GIT_USER_NAME  – git commit author name   (default: opencode-sync)
#
# Usage:
#   docker run --rm \
#     -e REPO=git@your-host:org/repo.git \
#     -v /host/data:/data \
#     -v /host/secret/id_rsa:/secrets/ssh/id_rsa:ro \
#     git-sync /usr/local/bin/git-sync.sh

WORKDIR="${WORKDIR:-/data}"
GITDIR="${GITDIR:-/data/repo-sync}"
SSH_KEY_PATH="${SSH_KEY_PATH:-/data/.ssh/id_rsa}"
SECRETPATH="${SECRETPATH:-/secrets/ssh/id_rsa}"

mkdir -p "$(dirname "$SSH_KEY_PATH")" "$GITDIR" "$WORKDIR" || true

# Ensure git/ssh/rsync are present (Alpine image path — no-op when pre-installed).
if ! command -v git >/dev/null 2>&1; then
  apk fix >/dev/null 2>&1 || true
  apk --no-cache --update add git openssh-client rsync ca-certificates >/dev/null 2>&1 || true
fi

# Prefer the secret mounted at SECRETPATH; fall back to any PVC-stored key.
if [ -f "$SECRETPATH" ] && [ ! -f "$SSH_KEY_PATH" ]; then
  cp "$SECRETPATH" "$SSH_KEY_PATH" || true
fi

# Generate a new key pair when no key exists at all.
if [ ! -f "$SSH_KEY_PATH" ]; then
  echo "SSH key not found; generating new key pair under $SSH_KEY_PATH"
  ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N "" -C "opencode@$(hostname)" || true
  echo "--- Public key (add this to your repo as a deploy key or user key) ---"
  cat "${SSH_KEY_PATH}.pub" || true
  echo "--- End public key ---"
fi

chmod 600 "$SSH_KEY_PATH" || true

export GIT_SSH_COMMAND="ssh -i $SSH_KEY_PATH -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

# Clone or initialise the repo in GITDIR.
if [ ! -d "$GITDIR/.git" ]; then
  if git clone "$REPO" "$GITDIR"; then
    echo "Cloned remote repo into $GITDIR"
  else
    echo "Clone failed; initializing empty repo at $GITDIR"
    git init "$GITDIR"
    cd "$GITDIR"
    git remote add origin "$REPO" || true
  fi
fi

# Sync files from WORKDIR into GITDIR (exclude the repo-sync folder and .git).
rsync -a --delete --exclude='repo-sync' --exclude='.git' "$WORKDIR/" "$GITDIR/"

cd "$GITDIR"
git config user.email "${GIT_USER_EMAIL:-opencode@daveshow.local}" || true
git config user.name "${GIT_USER_NAME:-opencode-sync}" || true
git config core.sshcommand "ssh -i ${SSH_KEY_PATH}" || true

# Commit and push only when there are staged changes.
git add -A
if ! git diff --staged --quiet; then
  git commit -m "Auto-sync: $(date -u +%Y-%m-%dT%H:%M:%SZ)" || true
  if git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
    git push origin HEAD || echo "git push failed"
  else
    git push origin master || git push origin main || echo "Initial push failed; ensure remote accepts pushes or create branch on remote"
  fi
else
  echo "No changes to commit"
fi
