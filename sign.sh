#!/bin/bash
set -e

# Configuration - set these environment variables or edit here
SIGNING_IDENTITY="${CODESIGN_IDENTITY:-Developer ID Application}"
TEAM_ID="${APPLE_TEAM_ID}"
APPLE_ID="${APPLE_ID}"
APP_PASSWORD="${APPLE_APP_PASSWORD}"

APP_NAME="Divvun-SEE-helper.app"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Divvun SEE Helper - Code Signing ===${NC}"

# Check if app exists
if [ ! -d "$APP_NAME" ]; then
    echo -e "${RED}Error: $APP_NAME not found${NC}"
    exit 1
fi

# Check if signing identity is available
if ! security find-identity -v -p codesigning | grep -q "$SIGNING_IDENTITY"; then
    echo -e "${RED}Error: Signing identity '$SIGNING_IDENTITY' not found${NC}"
    echo "Available identities:"
    security find-identity -v -p codesigning
    exit 1
fi

echo -e "${YELLOW}Step 1: Removing old signatures...${NC}"
codesign --remove-signature "$APP_NAME" 2>/dev/null || true

echo -e "${YELLOW}Step 2: Signing all executables...${NC}"
# Sign all executable files inside the app
find "$APP_NAME" -type f -perm +111 -exec codesign \
    --force \
    --sign "$SIGNING_IDENTITY" \
    --options runtime \
    --entitlements entitlements.plist \
    --timestamp \
    {} \;

echo -e "${YELLOW}Step 3: Signing the app bundle...${NC}"
codesign \
    --force \
    --deep \
    --sign "$SIGNING_IDENTITY" \
    --options runtime \
    --entitlements entitlements.plist \
    --timestamp \
    "$APP_NAME"

echo -e "${YELLOW}Step 4: Verifying signature...${NC}"
codesign --verify --deep --strict --verbose=2 "$APP_NAME"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ App signed successfully!${NC}"
    codesign -dv "$APP_NAME" 2>&1 | grep "Authority"
else
    echo -e "${RED}✗ Signature verification failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}=== Code signing complete ===${NC}"
echo ""
echo "Next steps:"
echo "  1. Run ./notarize.sh to submit for notarization"
echo "  2. Or manually: ditto -c -k --keepParent $APP_NAME $APP_NAME.zip"
echo "     xcrun notarytool submit $APP_NAME.zip --apple-id <email> --team-id <TEAM_ID> --password <app-password> --wait"
