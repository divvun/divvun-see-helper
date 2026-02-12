# Divvun-SEE-helper

Helper app for SubEthaEdit's Divvun modes and system-wide text analysis services.

**Current version: 1.1.0** - [See version history](VERSION.md)

##  Overview

SubEthaEdit is sandboxed and cannot execute external binaries directly. Divvun-SEE-helper is an unsandboxed helper app that provides access to HFST/Giella tools and creates system-wide macOS Services for text analysis.

## Main Features

1. **LexC Analysis for SubEthaEdit** - Analyzes words in LexC files and suggests missing lexicon entries
2. **Analyze Text Service** - System-wide service for morphological and syntactic analysis (opens in SubEthaEdit)
3. **Draw Dependency Tree Service** - System-wide service that visualizes dependency trees as PNG images

All features support multiple languages configured via `~/.divvun-see-helper-config`.

## System Requirements

- **macOS** 10.15 or newer
- **Python** 3.9+ (included in Xcode Command Line Tools)
- **[divvun-runtime](https://github.com/divvun/divvun-runtime)** - Text analysis engine
- **giella-core** - Must be cloned from GitHub
- **Graphviz** (for Draw Dependency Tree service)
  ```bash
  brew install graphviz
  ```
- **SubEthaEdit** (for Analyze Text service results)
- **Built analyser files** (`.drb`) - See [Building Analysers](#building-analysers) below

## Installation

### 1. Install the helper app

```bash
make install
```

This copies `Divvun-SEE-helper.app` to `~/Applications/`.

First-time use: Right-click the app and choose "Open" to approve it (macOS security requirement).

### 2. Install macOS Services (optional)

```bash
make install-service
```

This installs two Quick Actions:
- **Analyze Text** - Shows morphological/syntactic analysis
- **Draw Dependency Tree** - Creates visual dependency graph

Services appear in the Services menu when text is selected in any application.

### 3. Uninstall

```bash
make uninstall              # Remove helper app
make uninstall-service      # Remove services
```

## Configuration

Create `~/.divvun-see-helper-config`:

```bash
# Default language for analysis (ISO 639-3 code)
export DEFAULT_ANALYSIS_LANG="sme"

# Path to giellalt root directory (not language-specific)
export GTLANGS="$HOME/langtech/gut/giellalt"

# Path to giella-core (for missing.py and cg-dep2dot.py)
export GTCORE="$HOME/langtech/gut/giellalt/giella-core"

# Enable debug logging (default: false)
export ENABLE_LOGGING=true
```

### Building Analysers

To use text analysis features, you need a built `.drb` analyser file:

```bash
cd $GTLANGS/lang-sme  # or lang-sma, lang-smj, etc.
./configure --enable-analyser-tool --enable-tokenisers
make
```

The helper automatically finds `bundle.drb` or `${LANGCODE}.drb` in `tools/analysers/` directories.

## Features in Detail

### 1. LexC Analysis (SubEthaEdit Integration)

Analyzes words in LexC files and suggests missing lexicon entries using `missing.py` from giella-core.

**Usage:**
1. Open a `.lexc` file in SubEthaEdit
2. Press `⌃⌥⌘M` (Ctrl+Option+Cmd+M)
3. Get suggestions for missing entries

**How it works:**
- SubEthaEdit sends JSON request via clipboard
- Helper runs `missing.py` with the word list
- Results are returned via clipboard to SubEthaEdit

### 2. Analyze Text Service

System-wide macOS Service that analyzes selected text from any application.

**Usage:**
1. Select text in any app (Safari, Mail, TextEdit, etc.)
2. Right-click → Services → **Analyze Text**
3. Results open in SubEthaEdit (vislcg3 format)

**Output format:**
```
"<word>"
    "lemma" POS Tags... <W:0.0> @SYNTAG #id->head
```

Shows:
- Morphological analysis (lemma, part-of-speech, grammatical tags)
- Syntactic function tags
- Dependency relations

### 3. Draw Dependency Tree Service

System-wide service that creates visual dependency tree diagrams.

**Usage:**
1. Select text in any application  
2. Right-click → Services → **Draw Dependency Tree**
3. PNG image opens in Preview (can be copied)

**How it works:**
1. Analyzes text with `divvun-runtime`
2. Converts to dependency tree with `cg-dep2dot.py`
3. Generates PNG with Graphviz
4. Opens in Preview for viewing/copying

### Switching Languages

Change language by editing `~/.divvun-see-helper-config`:

```bash
export DEFAULT_ANALYSIS_LANG="sma"  # Change from sme to sma
```

All services use this setting. Make sure you have a built analyser for the language.

## Code Signing & Distribution (Developers)

To distribute without macOS security warnings, you need an Apple Developer account.

### 1. Configure signing

```bash
cp .env.example .env
# Edit .env with your Apple Developer credentials
source .env
```

Required variables:
- `CODESIGN_IDENTITY` - Your signing identity
- `APPLE_TEAM_ID` - Your Team ID
- `APPLE_ID` - Your Apple ID email  
- `APPLE_APP_PASSWORD` - App-specific password

### 2. Sign and notarize

```bash
make sign       # Code sign the app
make notarize   # Notarize with Apple
```

## Debugging

Enable logging in `~/.divvun-see-helper-config`:

```bash
export ENABLE_LOGGING=true
```

View logs:
```bash
tail -f ~/divvun-see-helper-debug.log
```

The log shows:
- Operations performed
- File paths searched
- Command execution details
- Error messages

## Advanced

### Communication Protocol

The helper uses clipboard-based JSON communication with base64-encoded input:

**Request format:**
```json
{
  "operation": "divvun_analyze",
  "lang": "sme",
  "gtlangs": "/path/to/giellalt",
  "input_words_b64": "<base64-encoded text>"
}
```

**Response format:**
```json
{
  "status": "success",
  "output": "<analysis result>"
}
```

**Error format:**
```json
{
  "status": "error",
  "message": "Error description",
  "details": "Additional information"
}
```

### Supported Operations

- `analyze_missing` - Find missing LexC entries (uses `missing.py`)
- `divvun_analyze` - Morphological and syntactic analysis (uses `divvun-runtime`)

### Architecture

```
Divvun-SEE-helper.app/
├── Contents/
│   ├── Info.plist
│   └── MacOS/
│       ├── run-helper                        # UTF-8 wrapper
│       ├── divvun-see-helper                 # Main script
│       ├── analyze-text-service.sh           # Service: text analysis
│       └── draw-dependency-tree-service.sh # Service: tree visualization
```

**Path handling:**
- Automatically extends `PATH` to include `~/.cargo/bin`, `/usr/local/bin`, `/opt/homebrew/bin`
- Essential for finding `divvun-runtime` in macOS Services context

**File search:**
- Searches for analysers: `${GTLANGS}/lang-${LANGCODE}/*/tools/analysers/{bundle.drb,${LANGCODE}.drb}`
- Uses newest file if multiple found (modification time)
- Searches up to 5 directory levels

## License

MIT - see LICENSE file.

## Contact

**Divvun/Giellatekno**
- GitHub: https://github.com/divvun
- Website: https://giellalt.github.io

## See Also

- [services/README.md](services/README.md) - Detailed service documentation
- [giella-core](https://github.com/giellalt/giella-core) - Core Giellalt tools
- [SubEthaEdit](https://subethaedit.net) - Collaborative text editor
