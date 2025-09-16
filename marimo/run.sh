#!/usr/bin/env bash
set -euo pipefail

BOLD='\033[[0;1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

LOG_FILE="/tmp/marimo.log"
DEBUG_LOG="/tmp/marimo-debug.log"

# Clear previous logs
> "$${LOG_FILE}"
> "$${DEBUG_LOG}"

printf "$${BOLD}Starting Marimo Notebook Server...$${NC}\n\n"

# Debug environment
printf "$${YELLOW}Debug: Environment info$${NC}\n" | tee -a "$${DEBUG_LOG}"
echo "User: $$(whoami)" | tee -a "$${DEBUG_LOG}"
echo "Working directory: $$(pwd)" | tee -a "$${DEBUG_LOG}"
echo "Python: $$(which python3 || echo 'python3 not found')" | tee -a "$${DEBUG_LOG}"
echo "UV: $$(which uv || echo 'uv not found')" | tee -a "$${DEBUG_LOG}"
echo "PATH: $$PATH" | tee -a "$${DEBUG_LOG}"
echo "PORT: ${PORT}" | tee -a "$${DEBUG_LOG}"
echo "" | tee -a "$${DEBUG_LOG}"

# Check if marimo is installed
printf "$${YELLOW}Checking marimo installation...$${NC}\n"
if uv pip list 2>&1 | tee -a "$${DEBUG_LOG}" | grep -q marimo; then
    printf "$${GREEN}✓ Marimo is already installed$${NC}\n"
    echo "Marimo version:" | tee -a "$${DEBUG_LOG}"
    uv pip show marimo 2>&1 | tee -a "$${DEBUG_LOG}"
else
    printf "$${YELLOW}Installing marimo...$${NC}\n"
    uv pip install marimo --break-system-packages 2>&1 | tee -a "$${DEBUG_LOG}"
    if [ $$? -eq 0 ]; then
        printf "$${GREEN}✓ Marimo installed successfully$${NC}\n"
    else
        printf "$${RED}✗ Failed to install marimo$${NC}\n"
        exit 1
    fi
fi

# Kill any existing marimo processes
printf "$${YELLOW}Cleaning up existing marimo processes...$${NC}\n"
if pgrep -f marimo; then
    echo "Found existing marimo processes:" | tee -a "$${DEBUG_LOG}"
    ps aux | grep marimo | grep -v grep | tee -a "$${DEBUG_LOG}"
    pkill -f "marimo" || true
    sleep 2
    printf "$${GREEN}✓ Killed existing processes$${NC}\n"
else
    printf "No existing marimo processes found\n"
fi

# Check port availability
printf "$${YELLOW}Checking port ${PORT} availability...$${NC}\n"
if lsof -i:${PORT} 2>/dev/null; then
    printf "$${RED}Warning: Port ${PORT} is already in use:$${NC}\n"
    lsof -i:${PORT} | tee -a "$${DEBUG_LOG}"
    # Try to kill whatever is using the port
    lsof -ti:${PORT} | xargs kill -9 2>/dev/null || true
    sleep 2
fi
printf "$${GREEN}✓ Port ${PORT} is available$${NC}\n"

# Change to home directory
printf "$${YELLOW}Changing to home directory...$${NC}\n"
cd /home/coder || cd ~ || cd /
echo "Current directory: $$(pwd)" | tee -a "$${DEBUG_LOG}"

# Start marimo with detailed logging
printf "$${BOLD}Starting marimo server...$${NC}\n"
echo "Command: uv run marimo edit --headless --host 0.0.0.0 --port ${PORT}" | tee -a "$${DEBUG_LOG}"

# Start marimo and capture PID
uv run marimo edit --headless --host 0.0.0.0 --port ${PORT} >> "$${LOG_FILE}" 2>&1 &
MARIMO_PID=$$!
echo "Started marimo with PID: $${MARIMO_PID}" | tee -a "$${DEBUG_LOG}"

# Give it time to start
printf "$${YELLOW}Waiting for marimo to initialize...$${NC}\n"
sleep 5

# Check if process is still running
if ps -p $${MARIMO_PID} > /dev/null; then
    printf "$${GREEN}✓ Marimo process is running (PID: $${MARIMO_PID})$${NC}\n"
    ps -fp $${MARIMO_PID} | tee -a "$${DEBUG_LOG}"
else
    printf "$${RED}✗ Marimo process died immediately$${NC}\n"
    printf "$${RED}Exit code: $$?$${NC}\n"
    printf "$${YELLOW}Marimo log output:$${NC}\n"
    cat "$${LOG_FILE}"
    printf "$${YELLOW}Debug log:$${NC}\n"
    cat "$${DEBUG_LOG}"
    exit 1
fi

# Check what's actually running
printf "$${YELLOW}Active marimo processes:$${NC}\n"
ps aux | grep marimo | grep -v grep | tee -a "$${DEBUG_LOG}"

# Check if port is now listening
printf "$${YELLOW}Checking if port ${PORT} is listening...$${NC}\n"
if lsof -i:${PORT} 2>/dev/null | tee -a "$${DEBUG_LOG}"; then
    printf "$${GREEN}✓ Port ${PORT} is listening$${NC}\n"
else
    printf "$${YELLOW}⚠ Port ${PORT} not yet listening$${NC}\n"
fi

# Health check with detailed output
printf "$${BOLD}Starting health checks...$${NC}\n"
max_attempts=30
attempt=1

while true; do
    printf "Health check attempt $${attempt}/$${max_attempts}: "
    
    # Try curl with verbose error reporting
    HTTP_CODE=$$(curl -s -o /dev/null -w "%%{http_code}" http://localhost:${PORT}/health 2>&1) || HTTP_CODE="000"
    
    if [ "$${HTTP_CODE}" = "200" ]; then
        printf "$${GREEN}✓ Success (HTTP $${HTTP_CODE})$${NC}\n"
        break
    else
        printf "$${YELLOW}Failed (HTTP $${HTTP_CODE})$${NC}\n"
        
        # Log current status
        echo "Attempt $${attempt} failed with code $${HTTP_CODE}" >> "$${DEBUG_LOG}"
        
        # Check if process is still alive
        if ! ps -p $${MARIMO_PID} > /dev/null; then
            printf "$${RED}✗ Marimo process died (PID $${MARIMO_PID} not found)$${NC}\n"
            break
        fi
    fi
    
    if [ $${attempt} -ge $${max_attempts} ]; then
        printf "$${RED}✗ Failed to start marimo after $${max_attempts} attempts$${NC}\n"
        break
    fi
    
    sleep 2
    attempt=$$((attempt + 1))
done

# Final status report
printf "\n$${BOLD}=== Final Status ===$${NC}\n"
if curl -s http://localhost:${PORT}/health > /dev/null 2>&1; then
    printf "$${GREEN}✅ Marimo is running successfully on port ${PORT}$${NC}\n"
    printf "📝 Application logs: $${LOG_FILE}\n"
    printf "🔍 Debug logs: $${DEBUG_LOG}\n"
else
    printf "$${RED}❌ Marimo failed to start properly$${NC}\n"
    printf "\n$${YELLOW}=== Application Logs ===$${NC}\n"
    tail -n 50 "$${LOG_FILE}"
    printf "\n$${YELLOW}=== Debug Logs ===$${NC}\n"
    tail -n 50 "$${DEBUG_LOG}"
    printf "\n$${YELLOW}=== Running Processes ===$${NC}\n"
    ps aux | grep marimo | grep -v grep
    exit 1
fi
