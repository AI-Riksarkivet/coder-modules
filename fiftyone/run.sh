#!/usr/bin/env bash
set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
MODULE_NAME="FiftyOne Module (pipx/uv)"
VENV_DIR="/home/coder/.venvs/fiftyone_uv" # Location for the virtual environment
PYTHON_EXEC="/usr/bin/python3"            # Python interpreter for creating the venv
DEFAULT_PORT="8080"                       # Default port if $PORT is not set
FIFTYONE_PACKAGE="fiftyone[desktop]"      # Install fiftyone with App dependencies

# --- Helper Functions ---
log() {
    echo "[$MODULE_NAME] $1"
}

# --- Prerequisites ---
log "Checking prerequisites..."
# Add any other specific prerequisite checks here if needed (e.g., disk space, specific libraries)
# Example: Check if python3 exists
if ! command -v "$PYTHON_EXEC" &> /dev/null; then
    log "ERROR: Python interpreter not found at $PYTHON_EXEC."
    exit 1
fi
log "Prerequisites met."

# --- Installation ---
log "Checking FiftyOne installation..."
if command_exists fiftyone; then
  log "FiftyOne command found."
  # Optional: Add logic here to check/upgrade version if FIFTYONE_VERSION is set
else
  log "FiftyOne not found. Installing via pip3..."
  # Determine package specifier based on version variable
  # package_spec="fiftyone" # Uncomment if using version variable

  # Use --user if sudo isn't available/desired, adjust as needed for your environment
  # If running as root in the container, --user might not be needed.
  # Using --upgrade ensures the latest version is installed if no specific version is requested.
  if pip3 install --upgrade fiftyone; then # Adjust package_spec if using version variable
    log "FiftyOne installed successfully."
  else
    log "ERROR: Failed to install FiftyOne."
    exit 1
fi
log "pipx found."

# --- Ensure uv is installed via pipx ---
log "Checking for uv installation..."
# Use 'pipx list' and parse JSON for robustness, or simple grep
if ! pipx list --json | grep -q '"name": "uv"'; then
    log "uv not found via pipx. Installing uv using pipx..."
    pipx install uv
    log "uv installed successfully using pipx."
else
    log "uv already installed via pipx."
fi
# Find the uv executable managed by pipx (adjust if pipx location differs)
UV_EXEC_PATH=$(pipx runpip uv -- location 2>/dev/null || echo "/home/coder/.local/bin/uv") # Best guess if runpip fails
if [ ! -x "$UV_EXEC_PATH" ]; then
    log "ERROR: Could not find uv executable. Looked for path from 'pipx runpip uv -- location' or guessed $UV_EXEC_PATH."
    exit 1
fi
log "Using uv executable at: $UV_EXEC_PATH"

# --- Ensure Virtual Environment ---
log "Checking for virtual environment at $VENV_DIR..."
if [ ! -d "$VENV_DIR/bin" ]; then # Check for bin directory as a sign of a valid venv
    log "Ensuring parent directory $(dirname "$VENV_DIR") exists..."
    mkdir -p "$(dirname "$VENV_DIR")"
    log "Creating virtual environment in $VENV_DIR using uv ($UV_EXEC_PATH)..."
    "$UV_EXEC_PATH" venv "$VENV_DIR" --python "$PYTHON_EXEC"
    log "Virtual environment created by uv."
else
    log "Virtual environment already exists at $VENV_DIR."
fi
# Define python executable within venv for installs
VENV_PYTHON_EXEC="$VENV_DIR/bin/python"

# --- Ensure FiftyOne is installed in venv ---
FIFTYONE_EXEC="$VENV_DIR/bin/fiftyone"
log "Checking FiftyOne installation in venv ($FIFTYONE_EXEC)..."
# Check if fiftyone command exists and runs
if ! "$FIFTYONE_EXEC" --version &> /dev/null; then
    log "FiftyOne not found or not working in venv. Installing/Updating $FIFTYONE_PACKAGE via uv pip..."
    # Use uv to install into the specific venv python environment
    "$UV_EXEC_PATH" pip install --python "$VENV_PYTHON_EXEC" "$FIFTYONE_PACKAGE"
    log "FiftyOne installed/updated successfully in venv using uv."
else
    CURRENT_VERSION=$("$FIFTYONE_EXEC" --version)
    log "FiftyOne ($CURRENT_VERSION) already installed in venv."
    # Optional: Add logic here to force update if needed
    # log "Attempting to update FiftyOne..."
    # "$UV_EXEC_PATH" pip install --python "$VENV_PYTHON_EXEC" --upgrade "$FIFTYONE_PACKAGE"
fi

# --- Determine Port for FiftyOne App ---
APP_PORT=""
# Check if $PORT is set, not empty, and is a number
if [[ -n "$PORT" && "$PORT" =~ ^[0-9]+$ ]]; then
    APP_PORT="$PORT"
    log "Using port $APP_PORT from \$PORT environment variable."
else
    # Warn if $PORT was set but invalid
    if [[ -n "$PORT" && ! "$PORT" =~ ^[0-9]+$ ]]; then
         log "Warning: \$PORT environment variable ('$PORT') is set but not a valid number. Using default port $DEFAULT_PORT."
    elif [[ -z "$PORT" ]]; then
         log "No \$PORT environment variable set or it is empty. Using default port $DEFAULT_PORT."
    fi
    APP_PORT="$DEFAULT_PORT"
fi
log "FiftyOne will attempt to run on port: $APP_PORT"

# --- Check if Port is Already in Use ---
# Use ss (requires iproute2 package) or fallback to netstat if available
log "Checking for existing process on port $APP_PORT..."
PORT_IN_USE=false
if command -v ss &> /dev/null; then
    if ss -tuln | grep -q ":$APP_PORT\b"; then
        PORT_IN_USE=true
    fi
elif command -v netstat &> /dev/null; then
     if netstat -tuln | grep -q ":$APP_PORT\b"; then
        PORT_IN_USE=true
    fi
else
    log "Warning: Cannot check if port is in use (ss and netstat commands not found)."
fi

if $PORT_IN_USE; then
    log "Warning: Port $APP_PORT appears to be in use by another process."
    log "Attempting to launch FiftyOne anyway. If it fails, stop the other process or choose a different port via the PORT environment variable."
    # Example: Set a different port and run -> PORT=5152 ./run.sh
else
     log "Port $APP_PORT appears free."
fi

# --- Start FiftyOne App ---
# Launch in the background (&)
# Listen on 0.0.0.0 to be accessible externally
log "Starting FiftyOne App server on port $APP_PORT (Address: 0.0.0.0) using $FIFTYONE_EXEC..."
"$FIFTYONE_EXEC" app launch --port "$APP_PORT" --address "0.0.0.0" &
FIFTYONE_PID=$!
log "FiftyOne process launched with PID: $FIFTYONE_PID"

# --- Wait and Check Status (Basic) ---
log "Waiting a few seconds for FiftyOne server to initialize..."
sleep 8 # Increased wait time as FiftyOne can take a moment

# Check if the process ID still exists
if ps -p $FIFTYONE_PID > /dev/null; then
   log "SUCCESS: FiftyOne server appears to be running (PID: $FIFTYONE_PID)."
   log "You should be able to access it at: http://<your-machine-ip-or-domain>:$APP_PORT"
   log "(If running locally or via port-forwarding, try http://localhost:$APP_PORT)"
   # If you want the script to stay running and wait for FiftyOne to exit:
   # wait $FIFTYONE_PID
else
   log "ERROR: FiftyOne process (PID: $FIFTYONE_PID) is no longer running."
   log "It likely failed to start properly. Check FiftyOne logs for details."
   log "Logs might be in: ~/.fiftyone/var/log/server.log or console output if not backgrounded."
   exit 1
fi

exit 0
