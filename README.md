# oc-docker

[![Build and Push Docker Image](https://github.com/daveshow/oc-docker/actions/workflows/docker-build-push.yml/badge.svg)](https://github.com/daveshow/oc-docker/actions/workflows/docker-build-push.yml)
[![Check for OpenCode Updates](https://github.com/daveshow/oc-docker/actions/workflows/check-updates.yml/badge.svg)](https://github.com/daveshow/oc-docker/actions/workflows/check-updates.yml)

Run [OpenCode AI](https://opencode.ai) in a secure, self-contained Docker environment with built-in support for MCP (Model Context Protocol) servers.

## What's Included

| Component | Purpose |
|-----------|---------|
| **OpenCode AI** | Latest version from the [official installer](https://opencode.ai/install) |
| **Node.js** | Latest from `node:alpine` base image, for npm-based MCP servers (`npx`) |
| **Python 3** | For Python-based MCP servers (`uvx`) |
| **uv** | Fast Python package manager |
| **Alpine Linux** | Minimal base image |

## Directory Structure

```
config/
├── opencode.jsonc     # Main config file (JSONC with comments & trailing commas)
├── agents/            # Custom agents
├── commands/          # Custom commands
├── plugins/           # Custom plugins
├── themes/            # Custom themes
├── tools/             # Custom tools
├── skills/            # Custom skills
└── modes/             # Custom modes

data/                  # Persisted automatically via volume mount
├── auth.json          # API credentials (auto-generated)
├── mcp-auth.json      # MCP OAuth tokens (auto-generated)
├── sessions/          # Conversation history
├── snapshots/         # Session checkpoints
└── log/               # Log files

projects/
└── (your code)        # Mount your project files here
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `OPENCODE_PORT` | Server port | `4096` |
| `OPENCODE_HOSTNAME` | Server hostname | `127.0.0.1` |
| `OPENCODE_CONFIG` | Path to config file | _(not set)_ |
| `OPENCODE_SERVER_PASSWORD` | Basic auth password | _(not set)_ |

## Quick Start

### Using Docker Compose (recommended)

```bash
# Clone the repository
git clone https://github.com/daveshow/oc-docker.git
cd oc-docker

# (Optional) Set a password
echo "OPENCODE_SERVER_PASSWORD=your-secret" > .env

# Build and start
docker compose up -d

# OpenCode is now available at http://localhost:4096
```

### Using Docker directly

```bash
docker build -t opencode .

docker run -d \
  -p 4096:4096 \
  -e OPENCODE_HOSTNAME=0.0.0.0 \
  -e OPENCODE_SERVER_PASSWORD=your-secret \
  -v ./config:/config \
  -v ./data:/data \
  -v ./projects:/projects \
  opencode
```

## Configuration

Edit `config/opencode.jsonc` to configure MCP servers and other settings. The default config enables:

- **filesystem** – access files under `/projects` via MCP
- **memory** – persistent in-memory storage across sessions
- **sqlite** – SQLite database at `/data/test.db`
- **context7** – remote MCP endpoint for library documentation
- **gh_grep** – remote MCP endpoint for GitHub code search

## Volumes

| Path | Purpose |
|------|---------|
| `/config` | OpenCode configuration and extensions |
| `/data` | Persistent data (sessions, logs, auth tokens) |
| `/projects` | Your project code |

## CI/CD

### Build and Push (`docker-build-push.yml`)

Builds a multi-arch image (`linux/amd64`, `linux/arm64`) and pushes it to the GitHub Container Registry (`ghcr.io`) on every push to `main`/`master`, on version tags, and via manual dispatch. Docker Hub is also supported when `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets are configured.

```
ghcr.io/daveshow/oc-docker:latest
```

### Nightly Update Check (`check-updates.yml`)

Runs every night at midnight UTC. Compares the [latest OpenCode release](https://github.com/sst/opencode/releases) against the version tracked in `.opencode-version`. When a new release is detected, the workflow automatically rebuilds and pushes the updated image, then commits the new version to `.opencode-version`.

You can also trigger the update check manually from the **Actions** tab.
