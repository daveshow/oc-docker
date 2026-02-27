#!/usr/bin/env bash
set -e

# Add opencode to PATH
export PATH="$HOME/.opencode/bin:$PATH"

# Environment variable defaults
OPENCODE_PORT="${OPENCODE_PORT:-4096}"
OPENCODE_HOSTNAME="${OPENCODE_HOSTNAME:-127.0.0.1}"

# Build opencode arguments
OPENCODE_ARGS=()

if [ -n "$OPENCODE_CONFIG" ]; then
    OPENCODE_ARGS+=("--config" "$OPENCODE_CONFIG")
fi

case "$1" in
    web)
        echo "Starting OpenCode server on ${OPENCODE_HOSTNAME}:${OPENCODE_PORT}..."
        exec opencode "${OPENCODE_ARGS[@]}" \
            serve \
            --port "$OPENCODE_PORT" \
            --hostname "$OPENCODE_HOSTNAME" \
            ${OPENCODE_SERVER_PASSWORD:+--password "$OPENCODE_SERVER_PASSWORD"}
        ;;
    *)
        # Pass through any other command directly to opencode
        exec opencode "${OPENCODE_ARGS[@]}" "$@"
        ;;
esac
