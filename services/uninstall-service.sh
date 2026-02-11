#!/bin/bash
#
# uninstall-service.sh
# Uninstalls the "Analyze Text" macOS service
#

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Uninstalling Divvun Text Analysis Service ===${NC}"
echo

# Paths
SERVICE_SCRIPT="$HOME/Applications/Divvun-SEE-helper.app/Contents/MacOS/analyze-text-service.sh"
WORKFLOW_DIR="$HOME/Library/Services"

# Remove service script
if [ -f "$SERVICE_SCRIPT" ]; then
    rm "$SERVICE_SCRIPT"
    echo -e "${GREEN}✓ Removed service script${NC}"
else
    echo -e "${YELLOW}Service script not found (already removed?)${NC}"
fi

# Remove workflows
REMOVED_COUNT=0

if [ -d "$WORKFLOW_DIR/Analyser tekst.workflow" ]; then
    rm -rf "$WORKFLOW_DIR/Analyser tekst.workflow"
    echo -e "${GREEN}✓ Removed: Analyser tekst${NC}"
    REMOVED_COUNT=$((REMOVED_COUNT + 1))
fi

if [ -d "$WORKFLOW_DIR/Analyze Text.workflow" ]; then
    rm -rf "$WORKFLOW_DIR/Analyze Text.workflow"
    echo -e "${GREEN}✓ Removed: Analyze Text${NC}"
    REMOVED_COUNT=$((REMOVED_COUNT + 1))
fi

if [ $REMOVED_COUNT -eq 0 ]; then
    echo -e "${YELLOW}No workflows found (already removed?)${NC}"
fi

echo
echo -e "${YELLOW}Refreshing Services database...${NC}"
/System/Library/CoreServices/pbs -flush 2>/dev/null || killall -KILL pbs 2>/dev/null || true
echo -e "${GREEN}✓ Services database refreshed${NC}"

echo
echo -e "${GREEN}=== Uninstallation Complete ===${NC}"
echo
echo "Note: Configuration file (~/.divvun-see-helper-config) was not removed."
echo "Remove it manually if you no longer need it."
echo
