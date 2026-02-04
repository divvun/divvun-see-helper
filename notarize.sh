#!/bin/bash
set -e

# Configuration - set these environment variables or edit here
TEAM_ID="${APPLE_TEAM_ID}"
APPLE_ID="${APPLE_ID}"
APP_PASSWORD="${APPLE_APP_PASSWORD}"

APP_NAME="Divvun-SEE-helper.app"
ZIP_NAME="Divvun-SEE-helper.zip"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Divvun SEE Helper - Notarization ===${NC}"

# Check required variables
if [ -z "$APPLE_ID" ]; then
    echo -e "${RED}Error: APPLE_ID environment variable not set${NC}"
    echo "Set it with: export APPLE_ID='your-apple-id@example.com'"
    exit 1
fi

if [ -z "$TEAM_ID" ]; then
    echo -e "${RED}Error: APPLE_TEAM_ID environment variable not set${NC}"
    echo "Set it with: export APPLE_TEAM_ID='YOUR_TEAM_ID'"
    exit 1
fi

if [ -z "$APP_PASSWORD" ]; then
    echo -e "${RED}Error: APPLE_APP_PASSWORD environment variable not set${NC}"
    echo "Generate an app-specific password at: https://appleid.apple.com/account/manage"
    echo "Set it with: export APPLE_APP_PASSWORD='xxxx-xxxx-xxxx-xxxx'"
    exit 1
fi

# Check if app exists
if [ ! -d "$APP_NAME" ]; then
    echo -e "${RED}Error: $APP_NAME not found${NC}"
    exit 1
fi

# Verify app is signed
echo -e "${YELLOW}Step 1: Verifying app signature...${NC}"
if ! codesign --verify --deep --strict "$APP_NAME" 2>/dev/null; then
    echo -e "${RED}Error: App is not properly signed. Run ./sign.sh first${NC}"
    exit 1
fi
echo -e "${GREEN}✓ App signature verified${NC}"

# Create zip archive
echo -e "${YELLOW}Step 2: Creating archive...${NC}"
rm -f "$ZIP_NAME"
ditto -c -k --keepParent "$APP_NAME" "$ZIP_NAME"
echo -e "${GREEN}✓ Archive created: $ZIP_NAME${NC}"

# Submit for notarization
echo -e "${YELLOW}Step 3: Submitting to Apple for notarization...${NC}"
echo "This may take a few minutes..."

xcrun notarytool submit "$ZIP_NAME" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$APP_PASSWORD" \
    --wait

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Notarization successful!${NC}"
    
    # Staple the notarization ticket
    echo -e "${YELLOW}Step 4: Stapling notarization ticket...${NC}"
    xcrun stapler staple "$APP_NAME"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Notarization ticket stapled to app${NC}"
        echo ""
        echo -e "${GREEN}=== Notarization complete ===${NC}"
        echo ""
        echo "Your app is now signed and notarized!"
        echo "You can distribute $APP_NAME or create an installer."
    else
        echo -e "${YELLOW}Warning: Could not staple ticket (app may still work with internet connection)${NC}"
    fi
    
    # Clean up zip
    rm -f "$ZIP_NAME"
else
    echo -e "${RED}✗ Notarization failed${NC}"
    echo "Check the notarization log with:"
    echo "  xcrun notarytool log <submission-id> --apple-id $APPLE_ID --team-id $TEAM_ID --password \$APPLE_APP_PASSWORD"
    exit 1
fi
