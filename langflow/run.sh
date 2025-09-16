#!/usr/bin/env bash
set -euo pipefail

BOLD='\033[[0;1m'
LANGFLOW_VENV="/home/coder/.langflow-venv"

printf "$${BOLD}Starting Langflow Server...\n\n"

# Create langflow.env file
cat > /home/coder/langflow.env << EOF
DO_NOT_TRACK=true
LANGFLOW_PORT=${PORT}
LANGFLOW_HOST=0.0.0.0
LANGFLOW_WORKERS=1
LANGFLOW_LOG_LEVEL=info
LANGFLOW_LOG_FILE=${LOG_PATH}
EOF

printf "Created environment file at /home/coder/langflow.env\n"

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

# Start Langflow with env-file
uv run --python "$${LANGFLOW_VENV}/bin/python" langflow run \
    --env-file /home/coder/langflow.env \
    --no-open-browser \
    >> ${LOG_PATH} 2>&1 &

printf "📂 Serving at http://localhost:${PORT}${SERVER_BASE_PATH}\n\n"
printf "📝 Logs at ${LOG_PATH}\n\n"
