#!/bin/bash
#
# analyze-dependency-tree-service.sh
# macOS Service for visualizing dependency trees
#
# This script:
# - Receives selected text from stdin
# - Analyzes it using divvun-runtime via divvun-see-helper
# - Converts the analysis to a dependency tree with cg-dep2dot.py
# - Generates a PNG image with graphviz
# - Opens the image in a viewer window
#

set -e

# Extend PATH to include common binary locations
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
GTLANGS="${GTLANGS:-$HOME/langtech/gut/giellalt}"
GTCORE="${GTCORE:-$HOME/langtech/gut/giellalt/giella-core}"

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

# Check if cg-dep2dot.py exists
CG_DEP2DOT="$GTCORE/devtools/cg-dep2dot.py"
if [ ! -f "$CG_DEP2DOT" ]; then
    osascript -e 'display alert "cg-dep2dot.py not found" message "Could not find '"$CG_DEP2DOT"'"'
    exit 1
fi

# Check if graphviz is installed
if ! command -v dot &> /dev/null; then
    osascript -e 'display alert "Graphviz not installed" message "Install with: brew install graphviz"'
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

# Create temporary file for analysis output
TEMP_VISLCG3=$(mktemp -t divvun-analysis).vislcg3
echo "$OUTPUT" > "$TEMP_VISLCG3"

# Convert to dot format
TEMP_DOT=$(mktemp -t divvun-dep).dot
if ! python3 "$CG_DEP2DOT" < "$TEMP_VISLCG3" > "$TEMP_DOT" 2>/dev/null; then
    rm -f "$TEMP_VISLCG3" "$TEMP_DOT"
    osascript -e 'display alert "Dependency conversion failed" message "Could not convert analysis to dependency tree format."'
    exit 1
fi

# Convert dot to PNG
TEMP_PNG=$(mktemp -t divvun-dep).png
if ! dot -Tpng "$TEMP_DOT" -o "$TEMP_PNG" 2>/dev/null; then
    rm -f "$TEMP_VISLCG3" "$TEMP_DOT" "$TEMP_PNG"
    osascript -e 'display alert "PNG generation failed" message "Could not generate PNG from dependency tree."'
    exit 1
fi

# Clean up intermediate files
rm -f "$TEMP_VISLCG3" "$TEMP_DOT"

# Open PNG in Preview (allows copying)
open -a Preview "$TEMP_PNG"

# Note: The temp PNG file will remain until manually deleted or system cleanup
