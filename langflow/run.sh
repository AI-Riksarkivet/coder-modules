#!/usr/bin/env bash
set -euo pipefail

BOLD='\033[[0;1m'
LANGFLOW_VENV="/home/coder/.langflow-venv"

printf "$${BOLD}Starting Langflow Server...\n\n"

# Create and setup langflow venv if it doesn't exist
if [ ! -d "$${LANGFLOW_VENV}" ]; then
    printf "Creating Langflow virtual environment...\n"
    uv venv "$${LANGFLOW_VENV}"
    
    printf "Installing Langflow in virtual environment...\n"
    uv pip install -q --python "$${LANGFLOW_VENV}/bin/python" langflow || {
        echo "ERROR: Failed to install Langflow"
        exit 1
    }
else
    printf "Using existing Langflow environment\n"
fi


printf "Starting Langflow server...\n"
cd /home/coder

# Start Langflow with CLI flags instead of env file
uv run --python "$${LANGFLOW_VENV}/bin/python" langflow run \ 
    --host 0.0.0.0 \
    --do-not-track False
    --port ${PORT} \
    --workers 1 \
    --log-level info \
    --log-file ${LOG_PATH} \
    --no-open-browser \
    >> ${LOG_PATH} 2>&1 &

printf "📂 Serving at http://localhost:${PORT}${SERVER_BASE_PATH}\n\n"
printf "📝 Logs at ${LOG_PATH}\n\n"
