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

# Start marimo with proper base URL if needed
if [ -n "${SERVER_BASE_PATH}" ]; then
    uv run marimo edit --headless --host 0.0.0.0 --port ${PORT} --base-url=${SERVER_BASE_PATH} >> ${LOG_PATH} 2>&1 &
else
    uv run marimo edit --headless --host 0.0.0.0 --port ${PORT} >> ${LOG_PATH} 2>&1 &
fi

printf "📂 Serving at http://localhost:${PORT}${SERVER_BASE_PATH}\n\n"

printf "📝 Logs at ${LOG_PATH}\n\n"
