#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="/Users/mac-JMACKO01/Developer/swift-snapshot-mackoj"

# Ensure container system is running
container system start || true

# Run tests
container run \
  --volume "${PROJECT_DIR}:/workspace" \
  --workdir "/workspace" \
  --tty \
  --interactive \
  --rm \
  swift:latest \
  swift test
