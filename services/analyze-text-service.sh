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
export PATH="$HOME/.cargo/bin:/usr/local/bin:/opt/homebrew/bin:$PATH"

# Read input text from stdin
INPUT_TEXT=$(cat)

# Check if we got any input
if [ -z "$INPUT_TEXT" ]; then
    osascript -e 'display alert "No text selected" message "Please select some text to analyze."'
    exit 1
fi

# Load configuration
CONFIG_FILE="$HOME/.divvun-see-helper-config"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Set defaults if not configured
DEFAULT_ANALYSIS_LANG="${DEFAULT_ANALYSIS_LANG:-sme}"
GTLANGS="${GTLANGS:-$HOME/langtech/gut/giellalt/lang-${DEFAULT_ANALYSIS_LANG}}"

# Check if divvun-see-helper exists
HELPER_APP="$HOME/Applications/Divvun-SEE-helper.app/Contents/MacOS/divvun-see-helper"
if [ ! -f "$HELPER_APP" ]; then
    osascript -e 'display alert "Divvun SEE Helper not found" message "Please install Divvun-SEE-helper.app to ~/Applications/"'
    exit 1
fi

# Check if divvun-runtime is installed
if ! command -v divvun-runtime &> /dev/null; then
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
echo -n "$JSON_REQUEST" | pbcopy

# Run the helper
"$HELPER_APP" 2>/dev/null

# Get response from clipboard
RESPONSE=$(pbpaste)

# Parse response
STATUS=$(echo "$RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('status', 'error'))" 2>/dev/null)

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
echo "$OUTPUT" > "$TEMP_FILE"

# Open in SubEthaEdit
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

exit 0
