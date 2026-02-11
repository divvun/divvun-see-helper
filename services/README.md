# Divvun Text Analysis Service

macOS system service for analyzing selected text using divvun-runtime and opening results in SubEthaEdit.

## Features

- **System-wide text analysis**: Works in any macOS application
- **Context menu integration**: Right-click → Services → "Analyze Text"
- **Automatic SubEthaEdit integration**: Results open in vislcg3 mode
- **Configurable language**: Set default analysis language in config file

## Installation

### Quick install

```bash
cd divvun-see-helper
make install-service
```

Or manually:

```bash
cd services
./install-service.sh
```

### Prerequisites

1. **Divvun-SEE-helper.app** must be installed:
   ```bash
   make install
   ```

2. **divvun-runtime** must be installed:
   ```bash
   brew install divvun/divvun/divvun-runtime
   ```

3. **Built analyser** (`.drb` file) for your language:
   ```bash
   cd /path/to/lang-xxx
   ./configure
   make
   ```

## Configuration

Edit `~/.divvun-see-helper-config`:

```bash
# Default language for text analysis (ISO 639-3 code)
export DEFAULT_ANALYSIS_LANG="sme"

# Path to language project
export GTLANGS="$HOME/langtech/gut/giellalt/lang-sme"
```

### Supported languages

Any language with a built `.drb` analyser:
- `sme` - North Sámi
- `sma` - South Sámi
- `smj` - Lule Sámi
- etc.

## Usage

1. **Select text** in any application (Safari, TextEdit, Mail, etc.)
2. **Right-click** on the selected text
3. Choose **Services → Analyze Text** (or "Analyser tekst")
4. Wait for analysis to complete
5. **SubEthaEdit opens** with the analyzed text in vislcg3 format

### Keyboard shortcut (optional)

You can assign a keyboard shortcut:

1. Open **System Settings**
2. Go to **Keyboard → Keyboard Shortcuts → Services**
3. Find "Analyze Text" under "Text"
4. Click to add a shortcut (e.g., `⌃⌥⌘A`)

## How it works

```
Selected text
    ↓
analyze-text-service.sh
    ↓
divvun-see-helper (divvun_analyze operation)
    ↓
divvun-runtime with .drb file
    ↓
SubEthaEdit (vislcg3 mode)
```

### Components

1. **analyze-text-service.sh**: Main service script
   - Receives text from stdin
   - Calls divvun-see-helper with divvun_analyze operation
   - Opens result in SubEthaEdit

2. **Automator Workflow**: macOS Quick Action
   - Appears in Services menu
   - Passes selected text to service script
   - Available in all applications

## Creating the Automator Workflow manually

If the workflow wasn't installed automatically:

1. Open **Automator**
2. Create new **Quick Action**
3. Set workflow receives **text** in **any application**
4. Add action: **Run Shell Script**
   - Shell: `/bin/bash`
   - Pass input: **to stdin**
   - Script:
     ```bash
     "$HOME/Applications/Divvun-SEE-helper.app/Contents/MacOS/analyze-text-service.sh"
     ```
5. Save as **"Analyze Text"** (or "Analyser tekst")
6. The service will now appear in the Services menu

## Troubleshooting

### Service doesn't appear in menu

1. **Restart Services**:
   ```bash
   /System/Library/CoreServices/pbs -flush
   ```
   Or log out and back in.

2. **Check installation**:
   ```bash
   ls -la ~/Library/Services/
   ```
   Should show "Analyze Text.workflow" or "Analyser tekst.workflow"

3. **Verify script location**:
   ```bash
   ls -la ~/Applications/Divvun-SEE-helper.app/Contents/MacOS/analyze-text-service.sh
   ```

### "divvun-runtime not installed" error

Install divvun-runtime:
```bash
brew install divvun/divvun/divvun-runtime
```

### "Could not find .drb file" error

Build the analyser for your language:
```bash
cd /path/to/lang-xxx
./configure
make
```

Verify the .drb file exists:
```bash
find ~/langtech -name "sme.drb"  # or your language code
```

### "No output" error

Check the helper log (if logging is enabled):
```bash
tail -50 ~/divvun-see-helper-debug.log
```

Enable logging in `~/.divvun-see-helper-config`:
```bash
export ENABLE_LOGGING=true
```

### SubEthaEdit doesn't open

The service will try to open the result with the default text editor if SubEthaEdit is not found. Install SubEthaEdit from:
- https://subethaedit.net

## Uninstallation

```bash
make uninstall-service
```

Or manually:

```bash
cd services
./uninstall-service.sh
```

This removes:
- Service script from Divvun-SEE-helper.app
- Automator workflows from ~/Library/Services/

The configuration file (`~/.divvun-see-helper-config`) is preserved.

## Advanced usage

### Multiple language services

You can create separate services for different languages by duplicating the Automator workflow and modifying the script to use a different language:

```bash
# Instead of reading from config, hardcode the language:
DEFAULT_ANALYSIS_LANG="sma"
GTLANGS="$HOME/langtech/gut/giellalt/lang-sma"
```

### Custom output handling

Modify `analyze-text-service.sh` to:
- Save output to a specific location
- Open in a different editor
- Post-process the analysis result
- Display in a notification instead

## License

MIT - see LICENSE file in parent directory.
