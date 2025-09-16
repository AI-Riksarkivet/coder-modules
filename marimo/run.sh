#!/usr/bin/env bash
set -euo pipefail

printf "Starting Marimo Notebook Server...\n"

# Install if needed
if ! uv pip list | grep -q marimo; then
    printf "Installing marimo...\n"
    uv pip install marimo --break-system-packages
fi

# Kill any existing marimo processes
pkill -f "marimo" || true
sleep 2

printf "Attempting to start marimo...\n"
cd /home/coder

# Try to run marimo directly first to see any errors
printf "Testing marimo command directly:\n"
uv run marimo --version

printf "\nStarting marimo server...\n"
# Run it in foreground first to see errors
timeout 5 uv run marimo edit --headless --host 0.0.0.0 --port ${PORT} || true

printf "\nNow starting in background...\n"
# Now try background
uv run marimo edit --host 0.0.0.0 --port ${PORT} > /tmp/marimo.log 2>&1 &
MARIMO_PID=$!

sleep 3

printf "Checking if marimo started (PID: $${MARIMO_PID})...\n"
if ps -p $${MARIMO_PID} > /dev/null; then
    printf "✓ Process is running\n"
    ps -fp $${MARIMO_PID}
else
    printf "✗ Process died\n"
    printf "Log contents:\n"
    cat /tmp/marimo.log
    
    printf "\nTrying alternative command...\n"
    # Try without uv run
    marimo edit --headless --host 0.0.0.0 --port ${PORT} > /tmp/marimo2.log 2>&1 &
    MARIMO_PID2=$!
    sleep 3
    
    if ps -p $${MARIMO_PID2} > /dev/null; then
        printf "✓ Alternative command worked (PID: $${MARIMO_PID2})\n"
    else
        printf "✗ Alternative also failed\n"
        cat /tmp/marimo2.log
    fi
fi

printf "Script completed\n"
