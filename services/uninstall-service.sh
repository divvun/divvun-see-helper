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
TEXT_SERVICE="$HOME/Applications/Divvun-SEE-helper.app/Contents/MacOS/analyze-text-service.sh"
DEP_SERVICE="$HOME/Applications/Divvun-SEE-helper.app/Contents/MacOS/analyze-dependency-tree-service.sh"
WORKFLOW_DIR="$HOME/Library/Services"

# Remove service scripts
REMOVED_SCRIPTS=0
if [ -f "$TEXT_SERVICE" ]; then
    rm "$TEXT_SERVICE"
    echo -e "${GREEN}✓ Removed text analysis service${NC}"
    REMOVED_SCRIPTS=$((REMOVED_SCRIPTS + 1))
fi

if [ -f "$DEP_SERVICE" ]; then
    rm "$DEP_SERVICE"
    echo -e "${GREEN}✓ Removed dependency tree service${NC}"
    REMOVED_SCRIPTS=$((REMOVED_SCRIPTS + 1))
fi

if [ $REMOVED_SCRIPTS -eq 0 ]; then
    echo -e "${YELLOW}Service scripts not found (already removed?)${NC}"
fi

# Remove workflows
REMOVED_COUNT=0

if [ -d "$WORKFLOW_DIR/Analyze Text.workflow" ]; then
    rm -rf "$WORKFLOW_DIR/Analyze Text.workflow"
    echo -e "${GREEN}✓ Removed: Analyze Text${NC}"
    REMOVED_COUNT=$((REMOVED_COUNT + 1))
fi

if [ -d "$WORKFLOW_DIR/Analyze Dependency Tree.workflow" ]; then
    rm -rf "$WORKFLOW_DIR/Analyze Dependency Tree.workflow"
    echo -e "${GREEN}✓ Removed: Analyze Dependency Tree${NC}"
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
