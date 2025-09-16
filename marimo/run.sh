#!/usr/bin/env bash
set -eu

echo "Starting Marimo Notebook Server..."

if ! uv pip list | grep -q marimo; then
    echo "Installing marimo..."
    uv pip install marimo --break-system-packages
fi

pkill -f "marimo.*--port ${PORT}" || true
sleep 2

# Start marimo in the background
cd /home/coder
nohup uv run marimo edit --headless --host 0.0.0.0 --port ${PORT} > /tmp/marimo.log 2>&1 &

# Wait for marimo to start
max_attempts=30
attempt=1
while ! curl -s "http://localhost:${PORT}/health" > /dev/null 2>&1; do
    if [ $attempt -ge $max_attempts ]; then
        echo "Failed to start marimo after ${max_attempts} attempts."
        cat /tmp/marimo.log
        exit 1
    fi
    echo "Waiting for marimo to start (attempt ${attempt}/${max_attempts})..."
    sleep 2
    attempt=$((attempt + 1))
done

echo "Marimo is running on port ${PORT}"
