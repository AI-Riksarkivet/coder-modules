#!/usr/bin/env bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# --- Configuration ---
# These variables are templated in by Terraform from main.tf
PORT="${PORT:-5151}"
# FIFTYONE_VERSION="${FIFTYONE_VERSION:-}" # Uncomment if using the version variable

# --- Helper Functions ---
log() {
  echo "[FiftyOne Module] $1"
}

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# --- Prerequisite Checks ---
log "Checking prerequisites..."
if ! command_exists python3; then
  log "ERROR: python3 command not found. Please install Python 3."
  exit 1
fi
if ! command_exists pip3; then
  log "ERROR: pip3 command not found. Please install pip3."
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
  # if [[ -n "$FIFTYONE_VERSION" ]]; then # Uncomment if using version variable
  #   package_spec="fiftyone==$FIFTYONE_VERSION" # Uncomment if using version variable
  # fi # Uncomment if using version variable

  # Use --user if sudo isn't available/desired, adjust as needed for your environment
  # If running as root in the container, --user might not be needed.
  # Using --upgrade ensures the latest version is installed if no specific version is requested.
  if pip3 install --upgrade fiftyone; then # Adjust package_spec if using version variable
    log "FiftyOne installed successfully."
  else
    log "ERROR: Failed to install FiftyOne."
    exit 1
  fi
fi

# --- Check if already running ---
# Attempt to find an existing FiftyOne process listening on the target port
log "Checking for existing FiftyOne process on port ${PORT}..."
if pgrep -f "fiftyone app launch --port ${PORT}" > /dev/null; then
    log "FiftyOne seems to be already running on port ${PORT}. Skipping launch."
    # Optional: Add a health check here if needed
    exit 0
fi

# --- Launch FiftyOne ---
# Ensure the FIFTYONE_DATABASE_DIR exists if needed, default is ~/.fiftyone/var/lib/mongo
# mkdir -p "$HOME/.fiftyone/var/lib/mongo"

log "Starting FiftyOne App server on port ${PORT}..."
# Launch in the background, listening on all interfaces (0.0.0.0) so the Coder tunnel can reach it.
# Redirect stdout and stderr to a log file.
fiftyone app launch --address 0.0.0.0 --port "${PORT}" > /tmp/fiftyone.log 2>&1 &
pid=$!

# --- Wait and Verify ---
log "Waiting a few seconds for FiftyOne to start (PID: $pid)..."
sleep 8 # Give it a bit more time to initialize

# Check if the process is still running
if ps -p $pid > /dev/null; then
  log "🚀 FiftyOne server started successfully!"
  log "Access it via the Coder app icon."
  log "Logs available at /tmp/fiftyone.log"
else
  log "ERROR: Failed to start FiftyOne server."
  log "Check logs for details:"
  # Show the last 10 lines of the log file if it exists
  if [[ -f "/tmp/fiftyone.log" ]]; then
    tail -n 10 /tmp/fiftyone.log
  else
    log "/tmp/fiftyone.log not found."
  fi
  exit 1
fi

# Keep the script running if needed, or exit if background process is sufficient
# For run_on_start, exiting after launching the background process is usually fine.
# If you need the script to manage the lifecycle, you'd use 'wait $pid' here,
# but that would block the Coder agent startup completion.
exit 0