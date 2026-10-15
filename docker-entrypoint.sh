#!/usr/bin/env bash
set -e

# Environment variable defaults
OPENCODE_PORT="${OPENCODE_PORT:-3000}"
OPENCODE_HOSTNAME="${OPENCODE_HOSTNAME:-127.0.0.1}"

# Build opencode arguments
OPENCODE_ARGS=()

if [ -n "${OPENCODE_CONFIG:-}" ]; then
	OPENCODE_ARGS+=("--config" "$OPENCODE_CONFIG")
fi

if [ -n "${OPENCODE_SERVER_PASSWORD:-}" ]; then
	OPENCODE_ARGS+=(--password "$OPENCODE_SERVER_PASSWORD")
fi

# Optional extra args, space-separated
if [ -n "${OPENCODE_EXTRA_ARGS:-}" ]; then
	read -r -a EXTRA <<< "$OPENCODE_EXTRA_ARGS"
	OPENCODE_ARGS+=("${EXTRA[@]}")
fi

case "$1" in
web)
	shift
	echo "Starting OpenCode server on ${OPENCODE_HOSTNAME}:${OPENCODE_PORT}..."
	exec opencode "${OPENCODE_ARGS[@]}" \
		web \
		--port "$OPENCODE_PORT" \
		--hostname "$OPENCODE_HOSTNAME" \
		"$@"
	;;
*)
	# Pass through any other command directly to opencode
	exec opencode "${OPENCODE_ARGS[@]}" "$@"
	;;
esac
