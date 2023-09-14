#!/bin/bash

# Colors
GREEN='\033[0;32m'
RESET='\033[0m' # Reset color to default

# Presentation
echo -e "${GREEN}--- 👾 Minion: Minimalist CLI wrapper for ChatGPT 👾 ---${RESET}"

# Validation
if [ -z "$OPENAI_API_KEY" ]; then
  echo "Missing OPENAI_API_KEY environment variable! Exiting..."
  exit 1
fi

function call_openai_api() {
  local PROMPT="$1"
  local INCLUDE_CHANGES="$2"

  CHANGES=$(git diff HEAD)

  if ("$INCLUDE_CHANGES" = true); then
    ESCAPED_CHANGES=$(echo "$CHANGES" | jq -sRr @json)
  else
    ESCAPED_CHANGES=""
  fi

  local API_URL="https://api.openai.com/v1/chat/completions"
  local MODEL="gpt-3.5-turbo-16k"
  local PAYLOAD=$(jq -n --arg model "$MODEL" --arg prompt "$PROMPT" --arg changes "$ESCAPED_CHANGES" '
  {
    messages: [
      {
        "role": "user",
        "content": ($prompt + "\n\n" + $changes)
      }
    ],
    "model": $model
  }')

  local RESULT=$(
    curl -X POST "$API_URL" \
      -H 'Content-Type: application/json' \
      -H "Authorization: Bearer $OPENAI_API_KEY" \
      -d "$PAYLOAD" | jq -r '.choices[0].message.content'
  )

  echo "$RESULT"
}

function ask() {
  local PROMPT="$1"
  echo "---> $PROMPT"
  local RESULT=$(call_openai_api "$PROMPT" false)

  echo "$RESULT"
}

function commit() {
  local PROMPT="Generate a Conventional Commits style commit message for the following changes. Use a compact and terse style. For things like dependencies and other verbose changes, bundle these changes into an overall change description. These are the changes:"
  local RESULT=$(call_openai_api "$PROMPT" true)

  echo -e "${GREEN}Generated commit message:${RESET}\n---------------------------\n"
  echo "$RESULT"
}

function review() {
  local PROMPT="You are a world-class software engineer. You have been assigned to review the following changes. You will provide actionable feedback while having a supportive tone. Focus on issues and problems, not mincing words. Highlight the issues and address each separately. If one issue is very similar to another, group them together. If one issue has effect on another, explain how. Give feedback on things that could be refactored or improved with common design patterns. Also, ensure any new code has tests if applicable (i.e. not for dependencies, version changes, configuration, or similar). These are the changes:"
  local RESULT=$(call_openai_api "$PROMPT" true)

  echo -e "${GREEN}Generated review:${RESET}\n---------------------------\n"
  echo "$RESULT"
}

function test() {
  local TEST_TOOL="Jest"
  local PROMPT="You are a world-class software engineer. You have been asked to write appropriate unit tests using $TEST_TOOL for the changes. Tests should only be made for our source code, not for dependencies, version changes, configuration, or similar. We are aiming for full code coverage, if possible. If there are no applicable changes, don't write any tests. These are the changes:"
  local RESULT=$(call_openai_api "$PROMPT" true)

  echo -e "${GREEN}Generated tests:${RESET}\n---------------------------\n"
  echo "$RESULT"
}

# Main function
start() {
  if [ $# -eq 0 ]; then
    echo "Usage: minion [ask|review|commit|test]"
    echo "Valid options: ask, review, commit, test"
    exit 1
  fi

  case "$1" in
  "ask")
    echo "Asking \"$2\"..."
    ask "$2"
    ;;
  "review")
    echo "Performing review..."
    review
    ;;
  "commit")
    echo "Writing commit message..."
    commit
    ;;
  "test")
    echo "Writing tests..."
    test
    ;;
  *)
    echo "Invalid option: $1"
    echo "Valid options: ask,review, commit, test"
    exit 1
    ;;
  esac

  exit 0
}

start "$@"
