.PHONY: install uninstall

APP_NAME = Divvun-SEE-helper.app
INSTALL_DIR = $(HOME)/Applications

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
