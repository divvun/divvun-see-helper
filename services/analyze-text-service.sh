#!/bin/bash
#
# analyze-text-service.sh
# macOS Service wrapper for Divvun text analysis
#
# This script:
# - Receives selected text from stdin
# - Analyzes it using divvun-runtime via divvun-see-helper
# - Opens the result in SubEthaEdit with vislcg3 mode
#

set -e

# Extend PATH to include common binary locations
# macOS Services run with minimal PATH, so we must add standard locations
export PATH="$HOME/bin:$HOME/.cargo/bin:/usr/local/bin:/opt/homebrew/bin:$PATH"

# Load configuration early to check for logging
CONFIG_FILE="$HOME/.divvun-see-helper-config"
ENABLE_LOGGING=false
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Helper function for logging
log() {
    if [ "$ENABLE_LOGGING" = "true" ]; then
        LOG_FILE="$HOME/divvun-see-helper-debug.log"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [analyze-text-service] $@" >> "$LOG_FILE"
    fi
}

log "=== Analyze Text Service Started ==="
log "PATH: $PATH"

# Read input text from stdin
INPUT_TEXT=$(cat)
log "Input text length: ${#INPUT_TEXT} characters"

# Check if we got any input
if [ -z "$INPUT_TEXT" ]; then
    log "ERROR: No input text received"
    osascript -e 'display alert "No text selected" message "Please select some text to analyze."'
    exit 1
fi

# Set defaults if not configured
DEFAULT_ANALYSIS_LANG="${DEFAULT_ANALYSIS_LANG:-sme}"
GTLANGS="${GTLANGS:-$HOME/langtech/gut/giellalt}"

log "Language: $DEFAULT_ANALYSIS_LANG"
log "GTLANGS: $GTLANGS"

# Check if divvun-see-helper exists
HELPER_APP="$HOME/Applications/Divvun-SEE-helper.app/Contents/MacOS/divvun-see-helper"
log "Helper app: $HELPER_APP"
if [ ! -f "$HELPER_APP" ]; then
    log "ERROR: Helper app not found at $HELPER_APP"
    osascript -e 'display alert "Divvun SEE Helper not found" message "Please install Divvun-SEE-helper.app to ~/Applications/"'
    exit 1
fi

# Check if divvun-runtime is installed
DIVVUN_RUNTIME_PATH=$(which divvun-runtime 2>/dev/null || echo "")
log "divvun-runtime: $DIVVUN_RUNTIME_PATH"
if [ -z "$DIVVUN_RUNTIME_PATH" ]; then
    log "ERROR: divvun-runtime not found in PATH"
    osascript -e 'display alert "divvun-runtime not installed" message "Install with: brew install divvun/divvun/divvun-runtime"'
    exit 1
fi

# Base64-encode the input text
INPUT_B64=$(echo -n "$INPUT_TEXT" | base64)

# Build JSON request
JSON_REQUEST=$(cat <<EOF
{
  "operation": "divvun_analyze",
  "lang": "$DEFAULT_ANALYSIS_LANG",
  "gtlangs": "$GTLANGS",
  "input_words_b64": "$INPUT_B64"
}
EOF
)

# Send request via clipboard
log "Sending JSON request to helper via clipboard"
echo -n "$JSON_REQUEST" | pbcopy

# Run the helper
log "Executing: $HELPER_APP"
"$HELPER_APP" 2>/dev/null

# Get response from clipboard
RESPONSE=$(pbpaste)
log "Received response from helper (length: ${#RESPONSE} characters)"

# Parse response
STATUS=$(echo "$RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('status', 'error'))" 2>/dev/null)
log "Response status: $STATUS"

if [ "$STATUS" != "success" ]; then
    # Extract error message
    ERROR_MSG=$(echo "$RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('message', 'Unknown error'))" 2>/dev/null)
    ERROR_DETAILS=$(echo "$RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('details', ''))" 2>/dev/null)
    
    # Show error dialog
    if [ -n "$ERROR_DETAILS" ]; then
        osascript -e "display alert \"Analysis failed\" message \"$ERROR_MSG\n\n$ERROR_DETAILS\""
    else
        osascript -e "display alert \"Analysis failed\" message \"$ERROR_MSG\""
    fi
    exit 1
fi

# Extract output
OUTPUT=$(echo "$RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('output', ''))" 2>/dev/null)

if [ -z "$OUTPUT" ]; then
    osascript -e 'display alert "No output" message "The analysis produced no output."'
    exit 1
fi

# Create temporary file with .vislcg3 extension
TEMP_FILE=$(mktemp -t divvun-analysis).vislcg3
log "Created temporary file: $TEMP_FILE"
echo "$OUTPUT" > "$TEMP_FILE"
log "Output written to file (${#OUTPUT} characters)"

# Open in SubEthaEdit
log "Opening result in SubEthaEdit"
if [ -d "/Applications/SubEthaEdit.app" ]; then
    open -a SubEthaEdit "$TEMP_FILE"
elif [ -d "$HOME/Applications/SubEthaEdit.app" ]; then
    open -a "$HOME/Applications/SubEthaEdit.app" "$TEMP_FILE"
else
    # SubEthaEdit not found, try to open with default text editor
    open "$TEMP_FILE"
fi

# Note: The temp file will remain in /tmp and be cleaned up by the system
# If SubEthaEdit saves it, it will be saved to a different location

log "=== Analyze Text Service Complete ==="
exit 0
