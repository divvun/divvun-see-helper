#!/bin/bash
#
# install-service.sh
# Installs the "Analyze Text" macOS service
#

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Installing Divvun Text Analysis Service ===${NC}"
echo

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Installation paths
SERVICE_SCRIPT="analyze-text-service.sh"
SERVICE_DEST="$HOME/Applications/Divvun-SEE-helper.app/Contents/MacOS/$SERVICE_SCRIPT"
WORKFLOW_DIR="$HOME/Library/Services"
CONFIG_FILE="$HOME/.divvun-see-helper-config"

# Step 1: Copy the service script
echo -e "${YELLOW}Step 1: Installing service script...${NC}"
if [ ! -d "$HOME/Applications/Divvun-SEE-helper.app" ]; then
    echo -e "${RED}Error: Divvun-SEE-helper.app not found in ~/Applications/${NC}"
    echo "Please run 'make install' first to install the main app."
    exit 1
fi

cp "$SCRIPT_DIR/$SERVICE_SCRIPT" "$SERVICE_DEST"
chmod +x "$SERVICE_DEST"
echo -e "${GREEN}✓ Service script installed to $SERVICE_DEST${NC}"
echo

# Step 2: Install Automator workflows
echo -e "${YELLOW}Step 2: Installing Automator workflows...${NC}"
mkdir -p "$WORKFLOW_DIR"

# Check which workflows exist
INSTALLED_COUNT=0

if [ -d "$SCRIPT_DIR/Analyser tekst.workflow" ]; then
    cp -R "$SCRIPT_DIR/Analyser tekst.workflow" "$WORKFLOW_DIR/"
    echo -e "${GREEN}✓ Installed: Analyser tekst (Norwegian)${NC}"
    INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
fi

if [ -d "$SCRIPT_DIR/Analyze Text.workflow" ]; then
    cp -R "$SCRIPT_DIR/Analyze Text.workflow" "$WORKFLOW_DIR/"
    echo -e "${GREEN}✓ Installed: Analyze Text (English)${NC}"
    INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
fi

if [ $INSTALLED_COUNT -eq 0 ]; then
    echo -e "${RED}Warning: No workflow files found${NC}"
    echo "You may need to create the Automator workflow manually."
    echo "See services/README.md for instructions."
fi
echo

# Step 3: Check/create configuration
echo -e "${YELLOW}Step 3: Checking configuration...${NC}"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Creating default configuration at $CONFIG_FILE"
    cat > "$CONFIG_FILE" << 'EOF'
# Divvun SEE Helper Configuration

# Enable debug logging (default: false)
export ENABLE_LOGGING=false

# Path to giella-core (optional)
# export GTCORE=/path/to/giella-core

# Text Analysis Service settings
export DEFAULT_ANALYSIS_LANG="sme"
export GTLANGS="$HOME/langtech/gut/giellalt/lang-sme"
EOF
    echo -e "${GREEN}✓ Created default configuration${NC}"
    echo -e "${YELLOW}  Please edit $CONFIG_FILE to set your paths${NC}"
else
    # Check if service settings exist in config
    if ! grep -q "DEFAULT_ANALYSIS_LANG" "$CONFIG_FILE"; then
        echo "Adding service settings to existing configuration..."
        cat >> "$CONFIG_FILE" << 'EOF'

# Text Analysis Service settings
export DEFAULT_ANALYSIS_LANG="sme"
export GTLANGS="$HOME/langtech/gut/giellalt/lang-sme"
EOF
        echo -e "${GREEN}✓ Added service settings to configuration${NC}"
    else
        echo -e "${GREEN}✓ Configuration already exists${NC}"
    fi
fi
echo

# Step 4: Refresh Services database
echo -e "${YELLOW}Step 4: Refreshing Services database...${NC}"
/System/Library/CoreServices/pbs -flush 2>/dev/null || killall -KILL pbs 2>/dev/null || true
echo -e "${GREEN}✓ Services database refreshed${NC}"
echo

# Step 5: Instructions
echo -e "${GREEN}=== Installation Complete ===${NC}"
echo
echo "The service is now installed and should appear in the Services menu."
echo
echo "To use it:"
echo "  1. Select some text in any application"
echo "  2. Right-click and choose Services → Analyze Text (or Analyser tekst)"
echo "  3. The analyzed text will open in SubEthaEdit"
echo
echo "Configuration:"
echo "  Edit $CONFIG_FILE"
echo "  to change the default language and project paths."
echo
echo "Note: If the service doesn't appear immediately, try logging out and"
echo "      logging back in, or wait a few minutes for the system to refresh."
echo
