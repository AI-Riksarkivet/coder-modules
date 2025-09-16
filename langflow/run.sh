#!/usr/bin/env bash
set -euo pipefail

BOLD='\033[[0;1m'
LANGFLOW_VENV="/home/coder/.langflow-venv"

printf "$${BOLD}Starting Langflow Server...\n\n"

# Set environment variables
export DO_NOT_TRACK=true
export LANGFLOW_PORT=${PORT}
export LANGFLOW_HOST="0.0.0.0"

# Create and setup langflow venv if it doesn't exist
if [ ! -d "$${LANGFLOW_VENV}" ]; then
    printf "Creating Langflow virtual environment...\n"
    uv venv "${LANGFLOW_VENV}"
    
    printf "Installing Langflow in virtual environment...\n"
    uv pip install -q --python "${LANGFLOW_VENV}/bin/python" langflow || {
        echo "ERROR: Failed to install Langflow"
        exit 1
    }
else
    printf "Using existing Langflow environment\n"
fi

# Kill any existing Langflow processes on the port
lsof -ti:${PORT} | xargs kill -9 2>/dev/null || true
sleep 2

printf "Starting Langflow server...\n"
cd /home/coder

# Start Langflow using uv run with the venv Python
# Note: Langflow doesn't have a --base-url flag, so we only use it with subdomain=true
uv run --python "${LANGFLOW_VENV}/bin/python" langflow run \
    --host 0.0.0.0 \
    --port ${PORT} \
    --no-open-browser \
    >> ${LOG_PATH} 2>&1 &

printf "📂 Serving at http://localhost:${PORT}${SERVER_BASE_PATH}\n\n"
printf "📝 Logs at ${LOG_PATH}\n\n"
