#!/bin/bash
#
# draw-dependency-tree-service.sh
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
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [draw-dependency-tree] $@" >> "$LOG_FILE"
    fi
}

log "=== Draw Dependency Tree Service Started ==="
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
GTCORE="${GTCORE:-$HOME/langtech/gut/giellalt/giella-core}"

log "Language: $DEFAULT_ANALYSIS_LANG"
log "GTLANGS: $GTLANGS"
log "GTCORE: $GTCORE"

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

# Check if cg-dep2dot.py exists
CG_DEP2DOT="$GTCORE/devtools/cg-dep2dot.py"
log "cg-dep2dot.py: $CG_DEP2DOT"
if [ ! -f "$CG_DEP2DOT" ]; then
    log "ERROR: cg-dep2dot.py not found at $CG_DEP2DOT"
    osascript -e 'display alert "cg-dep2dot.py not found" message "Could not find '"$CG_DEP2DOT"'"'
    exit 1
fi

# Check if graphviz is installed
DOT_PATH=$(which dot 2>/dev/null || echo "")
log "graphviz dot: $DOT_PATH"
if [ -z "$DOT_PATH" ]; then
    log "ERROR: dot (graphviz) not found in PATH"
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

# Create temporary file for analysis output
TEMP_VISLCG3=$(mktemp -t divvun-analysis).vislcg3
log "Created vislcg3 file: $TEMP_VISLCG3"
echo "$OUTPUT" > "$TEMP_VISLCG3"
log "Analysis output written (${#OUTPUT} characters)"

# Convert to dot format
TEMP_DOT=$(mktemp -t divvun-dep).dot
log "Created dot file: $TEMP_DOT"
log "Converting to dot format: python3 $CG_DEP2DOT < $TEMP_VISLCG3 > $TEMP_DOT"
if ! python3 "$CG_DEP2DOT" < "$TEMP_VISLCG3" > "$TEMP_DOT" 2>/dev/null; then
    log "ERROR: cg-dep2dot.py conversion failed"
    rm -f "$TEMP_VISLCG3" "$TEMP_DOT"
    osascript -e 'display alert "Dependency conversion failed" message "Could not convert analysis to dependency tree format."'
    exit 1
fi

# Convert dot to PNG
TEMP_PNG=$(mktemp -t divvun-dep).png
log "Created PNG file: $TEMP_PNG"
log "Converting to PNG: $DOT_PATH -Tpng $TEMP_DOT -o $TEMP_PNG"
if ! dot -Tpng "$TEMP_DOT" -o "$TEMP_PNG" 2>/dev/null; then
    log "ERROR: dot PNG conversion failed"
    rm -f "$TEMP_VISLCG3" "$TEMP_DOT" "$TEMP_PNG"
    osascript -e 'display alert "PNG generation failed" message "Could not generate PNG from dependency tree."'
    exit 1
fi

# Clean up intermediate files
log "Cleaning up intermediate files: $TEMP_VISLCG3, $TEMP_DOT"
rm -f "$TEMP_VISLCG3" "$TEMP_DOT"

# Open PNG in Preview (allows copying)
log "Opening PNG in Preview: $TEMP_PNG"
open -a Preview "$TEMP_PNG"

# Note: The temp PNG file will remain until manually deleted or system cleanup

log "=== Draw Dependency Tree Service Complete ==="
