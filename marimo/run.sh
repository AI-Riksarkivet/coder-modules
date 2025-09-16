#!/usr/bin/env bash
set -x  # Enable debug mode to see every command
set -euo pipefail

echo "=== Starting Marimo Setup ==="
echo "PORT: ${PORT}"
echo "PWD: $(pwd)"
echo "USER: $(whoami)"

# Check if marimo is installed
echo "=== Checking marimo installation ==="
if uv pip list | grep -q marimo; then
    echo "Marimo is already installed"
else
    echo "Installing marimo..."
    uv pip install marimo --break-system-packages || {
        echo "ERROR: Failed to install marimo"
        exit 1
    }
fi

echo "=== Verifying marimo installation ==="
uv pip show marimo || echo "WARNING: Could not show marimo package"

echo "=== Testing marimo command ==="
uv run python -c "import marimo; print(f'Marimo version: {marimo.__version__}')" || {
    echo "ERROR: Cannot import marimo"
    exit 1
}

echo "=== Killing existing processes ==="
pkill -f marimo || true

echo "=== Starting marimo server ==="
cd /home/coder

# Start with explicit Python invocation
echo "Running: uv run python -m marimo edit --headless --host 0.0.0.0 --port ${PORT}"
uv run python -m marimo edit --headless --host 0.0.0.0 --port ${PORT} &
MARIMO_PID=$!

echo "Started with PID: $${MARIMO_PID}"
sleep 5

echo "=== Checking process status ==="
if ps -p $${MARIMO_PID} > /dev/null; then
    echo "SUCCESS: Process is running"
    ps -fp $${MARIMO_PID}
    
    # Check port
    echo "=== Checking port ==="
    netstat -tulpn | grep ${PORT} || echo "Port ${PORT} not found in netstat"
    lsof -i:${PORT} || echo "Port ${PORT} not found in lsof"
else
    echo "ERROR: Process died"
fi

echo "=== Script completed ==="
