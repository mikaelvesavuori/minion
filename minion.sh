#!/bin/bash

MINION_VERSION="1.2.0"

# Colors
GREEN='\033[0;32m'
RESET='\033[0m' # Reset color to default

# Presentation
echo -e "${GREEN}--- 👾 Minion: Minimalist CLI wrapper for OpenAI APIs 👾 Version: ${MINION_VERSION} ---${RESET}"

# Validation
if [ -z "$OPENAI_API_KEY" ]; then
  echo "Missing OPENAI_API_KEY environment variable! Exiting..."
  exit 1
fi

function call_openai_api() {
  local PROMPT="$1"
  local INCLUDE_CHANGES="$2"
  local FILE="$3"

  CHANGES=$(git diff HEAD)
  ESCAPED_CHANGES=""

  if [ "$INCLUDE_CHANGES" = false ]; then
    if [ -n "$FILE" ]; then
      ESCAPED_CHANGES=$(cat $FILE | jq -sRr @json)
    else
      echo "FILE path not provided."
      exit 1
    fi
  fi

  if [ "$INCLUDE_CHANGES" = true ]; then
    ESCAPED_CHANGES=$(echo "$CHANGES" | jq -sRr @json)
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

  local RESPONSE=$(
    curl -X POST "$API_URL" \
      -H 'Content-Type: application/json' \
      -H "Authorization: Bearer $OPENAI_API_KEY" \
      -d "$PAYLOAD" \
      --silent
  )

  # Handle success/error cases
  if [[ $(echo "$RESPONSE" | jq 'has("error")') == "true" ]]; then
    ERROR_MESSAGE=$(echo "$RESPONSE" | jq -r '.error.message')
    RESULT="Error: $ERROR_MESSAGE"
  else
    RESULT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content')
  fi

  echo "$RESULT"
}

function ask() {
  local PROMPT="$1"
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
  local OPTION_1="" # Option switch
  local OPTION_2="" # Tool
  local OPTION_3="" # Path

  if [ -n "$1" ]; then OPTION_1="$1"; fi
  if [ -n "$2" ]; then OPTION_2="$2"; fi
  if [ -n "$3" ]; then OPTION_3="$3"; fi

  # First input must be a valid keyword
  options=("changes" "file" "api")
  if [[ ! "${options[@]}" =~ "$OPTION_1" ]]; then
    echo "Missing one of the required options: 'changes', 'file', or 'api'. Exiting..."
    exit 1
  fi

  # Ensure are required values are passed in
  if [[ ("$OPTION_1" == "file" || "$OPTION_1" == "api") ]]; then
    if [ -z "$OPTION_2" ]; then
      echo "Missing a value for the 'tool' option. Exiting..."
      exit 1
    fi

    if [ -z "$OPTION_3" ]; then
      echo "Missing a value for the 'path' option. Exiting..."
      exit 1
    fi
  fi

  # Set values
  local TEST_TYPE="unit"
  if [ "$OPTION_1" = "api" ]; then
    TEST_TYPE="integration"
  fi

  local TOOL="an appropriate tool"
  if [ -n "$OPTION_2" ]; then
    TOOL="$OPTION_2"
  fi

  # Create prompt
  local PROMPT_START="You are a world-class software engineer."
  local PROMPT_BASE="Tests should only be made for our source code, not for dependencies, version changes, configuration, or similar. We are aiming for full code coverage, if possible. If there are no applicable changes, don't write any tests. Only provide code, no explanations. These are the changes:"
  local PROMPT="$PROMPT_START You have been asked to write appropriate $TEST_TYPE tests using $TOOL for the changes. $PROMPT_BASE"

  if [ -n "$OPTION_3" ]; then
    local RESULT=$(call_openai_api "$PROMPT" false "$OPTION_3") # We got a path, so use the file at the path
  else
    local RESULT=$(call_openai_api "$PROMPT" true) # Use the current changes
  fi

  echo -e "${GREEN}Generated tests:${RESET}\n---------------------------\n"
  echo "$RESULT"
}

function diagram() {
  local VALID_TYPES=("uml" "mermaid" "sequence_diagram" "class_diagram" "flowchart" "graphviz")
  local TOOL="mermaid"

  for valid_value in "${VALID_TYPES[@]}"; do
    if [ "$1" == "$valid_value" ]; then
      TOOL="$1"
      break
    fi
  done

  echo "Using $TOOL as the diagram type..."

  local PROMPT="You are a world-class software architect. You have been asked to produce diagrams using $TOOL for the changes. Focus on our own code, and only add external dependencies if necessary. If it's unclear what the solution is, then don't make diagrams and voice your concern and reasons for stopping. These are the changes:"
  local RESULT=$(call_openai_api "$PROMPT" true)

  echo -e "${GREEN}Generated diagram:${RESET}\n---------------------------\n"
  echo "$RESULT"
}

# Main function
start() {
  if [ $# -eq 0 ]; then
    echo "Usage: minion [review|commit|test|ask|diagram]"
    echo "Valid options: review, commit, test, ask, diagram"
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
    test $2 $3 $4
    ;;
  "diagram")
    echo "Producing diagrams..."
    diagram $2
    ;;
  *)
    echo "Invalid option: $1"
    echo "Valid options: review, commit, test, ask, diagram"
    exit 1
    ;;
  esac

  exit 0
}

start "$@"
