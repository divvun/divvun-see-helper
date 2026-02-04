.PHONY: install uninstall sign notarize help

APP_NAME = Divvun-SEE-helper.app
INSTALL_DIR = $(HOME)/Applications

help:
	@echo "Available targets:"
	@echo "  make install    - Install app to ~/Applications"
	@echo "  make uninstall  - Remove app from ~/Applications"
	@echo "  make sign       - Code sign the app (requires Developer ID)"
	@echo "  make notarize   - Notarize the app with Apple (requires sign first)"
	@echo ""
	@echo "Environment variables for signing/notarizing:"
	@echo "  CODESIGN_IDENTITY - Your signing identity (default: 'Developer ID Application')"
	@echo "  APPLE_TEAM_ID     - Your Apple Team ID"
	@echo "  APPLE_ID          - Your Apple ID email"
	@echo "  APPLE_APP_PASSWORD - App-specific password from appleid.apple.com"

install:
	@echo "Installing $(APP_NAME) to $(INSTALL_DIR)..."
	@mkdir -p $(INSTALL_DIR)
	@rm -rf $(INSTALL_DIR)/$(APP_NAME)
	@cp -R $(APP_NAME) $(INSTALL_DIR)/
	@echo "✓ $(APP_NAME) installed successfully"
	@echo "  Location: $(INSTALL_DIR)/$(APP_NAME)"

uninstall:
	@echo "Uninstalling $(APP_NAME) from $(INSTALL_DIR)..."
	@rm -rf $(INSTALL_DIR)/$(APP_NAME)
	@echo "✓ $(APP_NAME) uninstalled successfully"

sign:
	@./sign.sh

notarize:
	@./notarize.sh
