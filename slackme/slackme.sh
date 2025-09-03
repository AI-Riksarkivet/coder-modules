#!/usr/bin/env sh
PROVIDER_ID=${PROVIDER_ID}
SLACK_MESSAGE=$(
  cat << "EOF"
${SLACK_MESSAGE}
EOF
)
SLACK_URL=${SLACK_URL:-https://slack.com}
DEFAULT_CHANNEL=${DEFAULT_CHANNEL} 

usage() {
  cat << EOF
slackme — Send a Slack notification when a command finishes OR send a message
Usage: 
  slackme <command>                        - Run command and notify to DM
  slackme -c <channel> <command>           - Run command and notify to channel
  slackme -m "message"                     - Send message to DM
  slackme -c <channel> -m "message"        - Send message to channel
  
Examples:
  slackme npm run long-build
  slackme -c "#ml-team" npm run long-build
  slackme -m "GPU allocation status"
  slackme -c "#ml-team" -m "2 GPUs in use"
EOF
}

# ... pretty_duration function stays the same ...

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

BOT_TOKEN=$(coder external-auth access-token $PROVIDER_ID)
if [ $? -ne 0 ]; then
  printf "Authenticate with Slack to be notified:\n$BOT_TOKEN\n"
  exit 1
fi

USER_ID=$(coder external-auth access-token $PROVIDER_ID --extra "authed_user.id")
if [ $? -ne 0 ]; then
  printf "Failed to get authenticated user ID:\n$USER_ID\n"
  exit 1
fi

# Parse arguments
CHANNEL=""
MESSAGE_MODE=false

# Check for channel flag
if [ "$1" = "-c" ] || [ "$1" = "--channel" ]; then
  shift
  CHANNEL="$1"
  shift
fi

# Check for message mode
if [ "$1" = "-m" ] || [ "$1" = "--message" ]; then
  MESSAGE_MODE=true
  shift
fi

# Determine target channel
if [ -n "$CHANNEL" ]; then
  TARGET_CHANNEL="$CHANNEL"
elif [ -n "$DEFAULT_CHANNEL" ]; then
  TARGET_CHANNEL="$DEFAULT_CHANNEL"
else
  TARGET_CHANNEL="$USER_ID"
fi

if [ "$MESSAGE_MODE" = true ]; then
  # Message mode - just send the message
  if [ $# -eq 0 ]; then
    echo "Error: No message provided"
    usage
    exit 1
  fi
  
  MESSAGE="$*"
  curl --silent -o /dev/null --header "Authorization: Bearer $BOT_TOKEN" \
    -G --data-urlencode "text=${MESSAGE}" \
    "$SLACK_URL/api/chat.postMessage?channel=$TARGET_CHANNEL&pretty=1"
else
  # Command mode - original behavior
  if [ $# -eq 0 ]; then
    echo "Error: No command provided"
    usage
    exit 1
  fi
  
  START=$(date +%s%N)
  $@
  END=$(date +%s%N)
  DURATION_MS=${DURATION_MS:-$(((END - START) / 1000000))}
  PRETTY_DURATION=$(pretty_duration $DURATION_MS)
  
  set -e
  COMMAND=$(echo $@)
  SLACK_MESSAGE=$(echo "$SLACK_MESSAGE" | sed "s|\\$COMMAND|$COMMAND|g")
  SLACK_MESSAGE=$(echo "$SLACK_MESSAGE" | sed "s|\\$DURATION|$PRETTY_DURATION|g")
  
  curl --silent -o /dev/null --header "Authorization: Bearer $BOT_TOKEN" \
    -G --data-urlencode "text=${SLACK_MESSAGE}" \
    "$SLACK_URL/api/chat.postMessage?channel=$TARGET_CHANNEL&pretty=1"
fi
