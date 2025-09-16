#!/usr/bin/env bash
set -euo pipefail

BOLD='\033[[0;1m'

printf "$${BOLD}Starting Marimo Notebook Server...\n\n"

# Check if marimo is installed
if ! uv pip list | grep -q marimo; then
  printf "Installing marimo...\n"
  uv pip install marimo --break-system-packages
fi

printf "🥳 Marimo installed! \n\n"

# Kill any existing marimo processes on the port
pkill -f "marimo.*--port ${PORT}" || true
sleep 2

printf "👷 Starting marimo in background... \n\n"

cd /home/coder

# Start marimo with uv run (not nohup)
uv run marimo edit --headless --host 0.0.0.0 --port ${PORT} >> /tmp/marimo.log 2>&1 &

# Give it a moment to start
sleep 3

printf "📂 Serving at http://localhost:${PORT} \n\n"

# Simple health check
max_attempts=30
attempt=1
while ! curl -s "http://localhost:${PORT}/health" > /dev/null 2>&1; do
    if [ $${attempt} -ge $${max_attempts} ]; then
        printf "Failed to start marimo after $${max_attempts} attempts.\n"
        printf "Marimo log output:\n"
        cat /tmp/marimo.log
        exit 1
    fi
    printf "Waiting for marimo to start (attempt $${attempt}/$${max_attempts})...\n"
    sleep 2
    attempt=$$((attempt + 1))
done

printf "✅ Marimo is running on port ${PORT}\n"
printf "📝 Logs at /tmp/marimo.log \n\n"
