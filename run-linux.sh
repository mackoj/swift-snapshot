#!/usr/bin/env bash
set -euo pipefail

# Ensure container system is running
container system start || true

# Run tests
container run \
  --volume ".:/workspace" \
  --workdir "/workspace" \
  --tty \
  --interactive \
  --rm \
  swift:latest \
  swift test
