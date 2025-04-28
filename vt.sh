#!/usr/bin/env bash

# Script to upload a file to VirusTotal API v3 using curl and jq

# --- Configuration ---
VT_API_URL_FILES="https://www.virustotal.com/api/v3/files"
VT_API_URL_LARGE_FILES="https://www.virustotal.com/api/v3/files/upload_url" # GET this first for >32MB
# Max size for free API (in bytes) - 32MB
MAX_FREE_SIZE_BYTES=$((32 * 1024 * 1024))

# --- Helper Functions ---

# Function to print error messages to stderr and exit
error_exit() {
  echo "Error: $1" >&2
  exit 1
}

# Function to check for required commands
check_command() {
  if ! command -v "$1" &> /dev/null; then
    error_exit "'$1' command not found. Please install it (e.g., using apt, brew, yum)."
  fi
}

# --- Argument Parsing ---
FILE_PATH=""
API_KEY_ARG=""

# Simple argument parsing loop
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -k|--api-key)
      API_KEY_ARG="$2"
      shift # past argument
      shift # past value
      ;;
    *)    # unknown option or positional argument (the file path)
      if [[ -z "$FILE_PATH" ]]; then
        FILE_PATH="$1"
      else
        error_exit "Unknown argument or multiple files specified: $1. Usage: $0 <file_path> [-k API_KEY]"
      fi
      shift # past argument
      ;;
  esac
done

# Check if file path was provided
if [[ -z "$FILE_PATH" ]]; then
  error_exit "No file path specified. Usage: $0 <file_path> [-k API_KEY]"
fi

# --- Dependency Checks ---
check_command "curl"
check_command "jq"
check_command "stat" # Needed for file size (Linux/macOS standard)

# --- API Key Retrieval ---
API_KEY="171eb81f0e1b09f22ced3c210cf7ac608f8a068843e48bdf86497347d98cdb81"
if [[ -n "$API_KEY_ARG" ]]; then
  echo "Using API key from command line argument."
  API_KEY="$API_KEY_ARG"
elif [[ -n "$VIRUSTOTAL_API_KEY" ]]; then
  echo "Using API key from VIRUSTOTAL_API_KEY environment variable."
  API_KEY="$VIRUSTOTAL_API_KEY"
else
  error_exit "VirusTotal API key not found. Set VIRUSTOTAL_API_KEY environment variable or use the -k/--api-key option."
fi

# --- File Validation ---
if [[ ! -f "$FILE_PATH" ]]; then
  error_exit "File not found at '$FILE_PATH'"
fi

# --- File Size and Upload URL ---
FILE_SIZE=0
# Use 'stat' command - syntax differs slightly between Linux and macOS
if [[ "$(uname)" == "Darwin" ]]; then # macOS
  FILE_SIZE=$(stat -f%z "$FILE_PATH")
else # Assume Linux
  FILE_SIZE=$(stat -c%s "$FILE_PATH")
fi

if [[ $? -ne 0 ]]; then
    error_exit "Could not determine file size using stat."
fi

echo "File: $(basename "$FILE_PATH")"
printf "Size: %.2f MB\n" $(echo "$FILE_SIZE / (1024*1024)" | bc -l) # Use bc for floating point division

UPLOAD_URL="$VT_API_URL_FILES"

# Handle large files (> 32MB)
if [[ "$FILE_SIZE" -gt "$MAX_FREE_SIZE_BYTES" ]]; then
  echo "File size exceeds 32MB. Attempting to get large file upload URL (may require premium API key)..."
  # Use curl to GET the special URL
  # -sS: Silent mode but show errors
  # -H: Add header
  LARGE_URL_RESPONSE=$(curl -sS --request GET \
    --url "$VT_API_URL_LARGE_FILES" \
    --header "x-apikey: $API_KEY")

  # Check curl exit status
  if [[ $? -ne 0 ]]; then
      echo "Warning: curl command failed while getting large file URL. Proceeding with standard upload (might fail)." >&2
  else
    # Use jq to extract the URL from the 'data' field. -e sets exit code if key not found. -r removes quotes.
    SPECIAL_URL=$(echo "$LARGE_URL_RESPONSE" | jq -er '.data')

    if [[ $? -eq 0 && -n "$SPECIAL_URL" ]]; then
      UPLOAD_URL="$SPECIAL_URL"
      echo "Using special upload URL: $UPLOAD_URL"
    else
      echo "Warning: Could not get or parse large file upload URL from response. Proceeding with standard upload (might fail)." >&2
      echo "API Response (Large URL): $LARGE_URL_RESPONSE" >&2
    fi
  fi
fi

# --- Perform Upload ---
echo "Uploading to $UPLOAD_URL..."

# Use curl to POST the file
# -sS: Silent mode but show errors
# -X POST: Specify POST request
# -H: Add header
# -F: Specify multipart/form-data (for file upload)
UPLOAD_RESPONSE=$(curl -sS --request POST \
  --url "$UPLOAD_URL" \
  --header "x-apikey: $API_KEY" \
  --form "file=@\"$FILE_PATH\"") # The @ tells curl it's a file path

# Check curl exit status for the upload
if [[ $? -ne 0 ]]; then
  error_exit "curl command failed during file upload. Check network or API key."
  # Note: curl might have printed its own error message already due to -S
fi

# --- Process Response ---
# Use jq to extract the analysis ID. -e sets exit code if key not found. -r removes quotes.
ANALYSIS_ID=$(echo "$UPLOAD_RESPONSE" | jq -er '.data.id')

if [[ $? -eq 0 && -n "$ANALYSIS_ID" ]]; then
  echo "Upload successful!"
  echo "Analysis ID: $ANALYSIS_ID"
  ANALYSIS_URL="https://www.virustotal.com/gui/file-analysis/$ANALYSIS_ID"
  echo "View analysis details at: $ANALYSIS_URL"
  echo "Note: Analysis may take some time to complete."
