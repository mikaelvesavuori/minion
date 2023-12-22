#!/bin/bash

MINION_VERSION="1.5.0"

# Colors
GREEN='\033[0;32m'
RESET='\033[0m' # Reset color to default

# Models
MODEL_1="gpt-3.5-turbo"
MODEL_2="gpt-3.5-turbo-16k"
MODEL_3="gpt-4"
MODEL_4="gpt-4-32k"
MODEL_5="gpt-4-turbo"

# File to temporarily write file contents to if using directory with files as input
FILE_CONTENTS_PROMPT_FILE="__minion.filecontents.prompt__.txt"

# Changes to use for prompting
ESCAPED_CHANGES=""

# Presentation
echo -e "${GREEN}--- 👾 Minion: Minimalist CLI wrapper for OpenAI APIs 👾 Version: ${MINION_VERSION} ---${RESET}"

# Validation
if [ -z "$OPENAI_API_KEY" ]; then
  echo "Missing OPENAI_API_KEY environment variable! Exiting..."
  exit 1
fi

#
# Call the Open AI APIs.
#
call_openai_api() {
  local PROMPT="$1"
  local INCLUDE_CHANGES="$2"
  local PATH_TO_USE="$3"
  local IS_DIR="$4"

  get_changes "$PATH_TO_USE" "$IS_DIR"

  echo
  echo "Using model: $MODEL"

  local API_URL="https://api.openai.com/v1/chat/completions"
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

#
# Get the changes from the expected location (Git, file, directories with files).
#
get_changes() {
  local PATH_TO_USE="$1"
  local IS_DIR="$2"

  local CHANGES=""

  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    CHANGES=$(git diff HEAD)
  fi

  # Use changes as part of prompt
  if [ "$INCLUDE_CHANGES" = true ]; then
    ESCAPED_CHANGES=$(echo "$CHANGES" | jq -sRr @json)
  fi

  # Use file content as part of prompt
  if [ "$INCLUDE_CHANGES" = false ]; then

    if [ -n "$PATH_TO_USE" ]; then
      # Use all relevant files in directory as input
      if [ "$IS_DIR" == "true" ]; then
        extract_file_contents_into_prompt "$PATH_TO_USE"
        ESCAPED_CHANGES=$(cat "$FILE_CONTENTS_PROMPT_FILE")
      else
        # Use individual file
        ESCAPED_CHANGES=$(cat "$PATH_TO_USE" | jq -sRr @json)
      fi
    fi
  fi
}

#
# The "ask" use case.
#
ask() {
  local PROMPT="$1"
  local RESULT=$(call_openai_api "$PROMPT" false)

  echo "$RESULT"
}

#
# The "commit" use case.
#
commit() {
  local PROMPT="Generate a Conventional Commits style commit message for the following changes. Use a compact and terse style. For things like dependencies and other verbose changes, bundle these changes into an overall change description. These are the changes:"
  local RESULT=$(call_openai_api "$PROMPT" true)

  echo -e "${GREEN}Generated commit message:${RESET}\n---------------------------\n"
  echo "$RESULT"
}

#
# The "review" use case.
#
review() {
  local OPTION_1="" # Option switch
  local OPTION_2="" # Path

  if [ -n "$1" ]; then OPTION_1="$1"; fi
  if [ -n "$2" ]; then OPTION_2="$2"; fi

  # First input must be a valid keyword
  OPTIONS=("changes" "file" "directory")
  if [[ ! "${OPTIONS[@]}" =~ "$OPTION_1" ]]; then
    echo "Missing one of the required options: 'changes', 'file', or 'directory'. Exiting..."
    exit 1
  fi

  # Ensure all required values are passed in
  if [[ ("$OPTION_1" == "file") ]] && [ -z "$OPTION_2" ]; then
    echo "Missing a value for the 'path' option. Exiting..."
    exit 1
  fi

  local IS_DIR=""
  if [ "$OPTION_1" == "directory" ]; then
    IS_DIR="true"
  fi

  local PROMPT="You are a world-class software engineer. You have been assigned to review the following code. You will provide actionable feedback while having a supportive tone. Focus on issues and problems, not mincing words. Highlight the issues and address each separately. If one issue is very similar to another, group them together. If one issue has effect on another, explain how. Give feedback on things that could be refactored or improved with common design patterns. Also, ensure any new code has tests if applicable (i.e. not for dependencies, version changes, configuration, or similar). These are the changes:"

  if [ -n "$OPTION_2" ]; then
    local RESULT=$(call_openai_api "$PROMPT" false "$OPTION_2" "$IS_DIR") # We got a path, so use the file/directory at the path
  else
    local RESULT=$(call_openai_api "$PROMPT" true) # Use the current changes
  fi

  echo -e "${GREEN}Generated review:${RESET}\n---------------------------\n"
  echo "$RESULT"
}

#
# The "test" use case.
#
test() {
  local OPTION_1="" # Option switch
  local OPTION_2="" # Tool
  local OPTION_3="" # Path

  if [ -n "$1" ]; then OPTION_1="$1"; fi
  if [ -n "$2" ]; then OPTION_2="$2"; fi
  if [ -n "$3" ]; then OPTION_3="$3"; fi

  # First input must be a valid keyword
  local OPTIONS=("changes" "file" "api")
  if [[ ! "${OPTIONS[@]}" =~ "$OPTION_1" ]]; then
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

#
# The "diagram" use case.
#
diagram() {
  local OPTION_1="" # Option switch
  local OPTION_2="" # Tool
  local OPTION_3="" # Path

  if [ -n "$1" ]; then OPTION_1="$1"; fi
  if [ -n "$2" ]; then OPTION_2="$2"; fi
  if [ -n "$3" ]; then OPTION_3="$3"; fi

  # First input must be a valid keyword
  local OPTIONS=("changes" "file")
  if [[ ! "${OPTIONS[@]}" =~ "$OPTION_1" ]]; then
    echo "Missing one of the required options: 'changes' or 'file'. Exiting..."
    exit 1
  fi

  local VALID_TYPES=("uml" "mermaid" "sequence_diagram" "class_diagram" "flowchart" "graphviz")
  local TOOL="Mermaid"

  for VALID_VALUE in "${VALID_TYPES[@]}"; do
    if [ "$OPTION_2" == "$VALID_VALUE" ]; then
      TOOL="$2"
      break
    fi
  done

  # Ensure are required values are passed in
  if [[ "$OPTION_1" == "file" ]]; then
    if [ -z "$OPTION_2" ]; then
      echo "Missing a value for the 'tool' option. Exiting..."
      exit 1
    fi

    if [ -z "$OPTION_3" ]; then
      echo "Missing a value for the 'path' option. Exiting..."
      exit 1
    fi
  fi

  echo "Using $TOOL as the diagram type..."

  local PROMPT="You are a world-class software architect. You have been asked to produce diagrams using $TOOL for the changes. Focus on our own code, and only add external dependencies if necessary. If it's unclear what the solution is, then don't make diagrams and voice your concern and reasons for stopping. These are the changes:"

  if [ -n "$OPTION_3" ]; then
    local RESULT=$(call_openai_api "$PROMPT" false "$OPTION_3") # We got a path, so use the file at the path
  else
    local RESULT=$(call_openai_api "$PROMPT" true) # Use the current changes
  fi

  echo -e "${GREEN}Generated diagram:${RESET}\n---------------------------\n"
  echo "$RESULT"
}

#
# Load a Minion configuration file from the current directory.
#
load_config() {
  local CONFIG_FILE="minion.json"
  local MODEL=""

  if [ -e "$CONFIG_FILE" ]; then
    CONFIG_DATA=$(jq -c . "$CONFIG_FILE")

    if [ $? -eq 0 ]; then
      MODEL=$(echo "$CONFIG_DATA" | jq -r .model)
      echo "$MODEL"
    fi
  else
    echo
  fi
}

#
# Extract file contents from a directory source into an aggregated prompt.
#
extract_file_contents_into_prompt() {
  local SEARCH_DIR=""

  if [ -n "$1" ]; then SEARCH_DIR="$1"; fi
  if [ -z "$SEARCH_DIR" ]; then echo "Missing directory!" && exit 1; fi

  # Make sure the old copy is not in the way
  rm -f "$FILE_CONTENTS_PROMPT_FILE"

  # List of common programming file extensions
  local FILE_EXTENSIONS=("js" "py" "java" "c" "cpp" "cs" "php" "rb" "sql" "swift" "go" "ts" "pl" "rs" "dart" "lua" "kt" "groovy" "scala" "r")
  # Define an array of directories to ignore
  local IGNORED_DIRS=("node_modules" "build" "dist" ".esbuild" ".webpack" ".serverless" "coverage" "jest-coverage")

  find "$SEARCH_DIR" -type f | while read -r file; do
    local RELATIVE_PATH=$(basename "$(dirname "$file")")/$(basename "$file")

    # Check if the file extension is in the list of allowed extensions
    local FILE_EXTENSION="${file##*.}"
    if [[ ! " ${FILE_EXTENSIONS[@]} " =~ " $FILE_EXTENSION " ]]; then
      continue
    fi

    # Check if any part of the file path contains any of the ignored directories
    local FULL_PATH="$file"
    local IGNORED=false

    for DIRECTORY in "${IGNORED_DIRS[@]}"; do
      if echo "$FULL_PATH" | grep -q "/$DIRECTORY/"; then
        IGNORED=true
        break
      fi
    done

    if [ "$IGNORED" = true ]; then
      continue
    fi

    echo -e "Relative Path: $RELATIVE_PATH\n\\n\"\"\"" >>$FILE_CONTENTS_PROMPT_FILE
    cat "$file" >>$FILE_CONTENTS_PROMPT_FILE
    echo -e "\"\"\"\\n" >>$FILE_CONTENTS_PROMPT_FILE
  done
}

#
# Orchestrate the startup and the various use cases.
#
start() {
  if [ $# -le 1 ]; then
    echo "Usage: minion [review|commit|test|ask|diagram]"
    echo "Valid options: review, commit, test, ask, diagram"
    exit 1
  fi

  local MODEL="$1"
  shift # Shift the arguments so $@ contains only the command line arguments
  echo

  case "$1" in
  "ask")
    echo "Asking \"$2\"..."
    ask "$2"
    ;;
  "review")
    echo "Performing review..."
    review $2 $3
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
    diagram $2 $3 $4
    ;;
  *)
    echo "Invalid option: $1"
    echo "Valid options: review, commit, test, ask, diagram"
    exit 1
    ;;
  esac

  exit 0
}

#
# Display the model menu.
#
model_menu() {
  echo "Choose an OpenAI API Model:"
  echo "1. $MODEL_1"
  echo "2. $MODEL_2"
  echo "3. $MODEL_3"
  echo "4. $MODEL_4"
  echo "5. $MODEL_5"
  echo "6. Exit"
}

#
# Handle the choice of AI model.
#
choose_model() {
  # Check if we have a model set from the configuration file
  local CONFIG_MODEL=$(load_config)
  if [ -n "$CONFIG_MODEL" ]; then
    MODEL="$CONFIG_MODEL"
    return 0
  fi

  # A model was not provided through configuration, let user enter their choice
  model_menu

  local CHOICE
  read -p "Enter choice [1-6]: " CHOICE

  case $CHOICE in
  1) MODEL="$MODEL_1" ;;
  2) MODEL="$MODEL_2" ;;
  3) MODEL="$MODEL_3" ;;
  4) MODEL="$MODEL_4" ;;
  5) MODEL="$MODEL_5" ;;
  6) exit 0 ;;
  *) echo "Invalid choice." && return 1 ;;
  esac

  return 0
}

#
# Start the program.
#
while true; do
  choose_model && break
done

start "$MODEL" "$@"
