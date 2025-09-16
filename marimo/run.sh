#!/usr/bin/env bash
set -euo pipefail

BOLD='\033[[0;1m'
MARIMO_VENV="/home/coder/.marimo-venv"

printf "$${BOLD}Starting Marimo Notebook Server...\n\n"

# Create and setup marimo venv if it doesn't exist
if [ ! -d "$${MARIMO_VENV}" ]; then
    printf "Creating marimo virtual environment...\n"
    uv venv "$${MARIMO_VENV}"
    
    printf "Installing marimo in virtual environment...\n"
    uv pip install -q --python "$${MARIMO_VENV}/bin/python" marimo || {
        echo "ERROR: Failed to install marimo"
        exit 1
    }
else
    printf "Using existing marimo environment\n"
fi


printf "Starting marimo server...\n"
cd /home/coder

# Start marimo using uv run with the venv Python
if [ -n "${SERVER_BASE_PATH}" ]; then
    uv run --python "$${MARIMO_VENV}/bin/python" marimo edit --headless --watch --host 0.0.0.0 --port ${PORT} --no-token --base-url --sandbox=${SERVER_BASE_PATH} >> ${LOG_PATH} 2>&1 &
else
    uv run --python "$${MARIMO_VENV}/bin/python" marimo edit --headless --watch --host 0.0.0.0 --port ${PORT} --no-token  --sandbox>> ${LOG_PATH} 2>&1 &
fi

printf "📂 Serving at http://localhost:${PORT}${SERVER_BASE_PATH}\n\n"
printf "📝 Logs at ${LOG_PATH}\n\n"
