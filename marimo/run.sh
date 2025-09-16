#!/usr/bin/env bash
set -euo pipefail

echo "=== Starting Marimo Setup ==="
echo "PORT: ${PORT}"

# Check if marimo is installed
if ! uv pip list | grep -q marimo; then
    echo "Installing marimo..."
    uv pip install marimo --break-system-packages || {
        echo "ERROR: Failed to install marimo"
        exit 1
    }
fi

echo "=== Testing marimo ==="
uv run python -c "import marimo; print(f'Marimo version: {marimo.__version__}')"

# Kill ONLY marimo server processes, not the script itself
echo "=== Cleaning up old processes ==="
pkill -f "marimo edit" || true
pkill -f "marimo server" || true
# Don't use pkill -f marimo as it kills the script!

sleep 2

echo "=== Starting marimo server ==="
cd /home/coder

# Start marimo
uv run python -m marimo edit --headless --host 0.0.0.0 --port ${PORT} > /tmp/marimo.log 2>&1 &
MARIMO_PID=$!

echo "Started marimo with PID: $${MARIMO_PID}"
sleep 5

# Check if it's running
if ps -p $${MARIMO_PID} > /dev/null; then
    echo "✓ Marimo is running"
    
    # Check port
    if lsof -i:${PORT} > /dev/null 2>&1; then
        echo "✓ Port ${PORT} is listening"
    else
        echo "⚠ Port ${PORT} not listening yet"
    fi
    
    # Test health endpoint
    if curl -s http://localhost:${PORT}/health > /dev/null 2>&1; then
        echo "✓ Health check passed"
    else
        echo "⚠ Health check failed, but process is running"
    fi
else
    echo "✗ Process died. Log contents:"
    cat /tmp/marimo.log
    exit 1
fi

echo "=== Marimo successfully started on port ${PORT} ==="
