#!/usr/bin/env bash
set -euo pipefail

# Check if marimo is installed
if ! uv pip list | grep -q marimo; then
    echo "Installing marimo..."
    uv pip install -q marimo --break-system-packages || {
        echo "ERROR: Failed to install marimo"
        exit 1
    }
fi

echo "=== Starting marimo server ==="
cd /home/coder

# Start marimo
uv run marimo edit --headless --host 10.100.127.31${BASE_URL} --port ${PORT} > ${LOG_PATH} 2>&1 &
