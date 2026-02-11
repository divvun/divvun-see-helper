# Divvun-SEE-helper

Helper app for SubEthaEdit's Divvun modes, designed to circumvent macOS sandbox restrictions.

## About

SubEthaEdit is a sandboxed macOS application that cannot execute external binaries directly. Divvun-SEE-helper.app is an unsandboxed helper app that runs outside the sandbox and provides access to tools like `hfst-lookup`, `missing.py`, and other HFST/Giella tools.

## Features

- **Lexc-lexicalise-missing**: Analyzes words in LexC files and suggests missing lexicon entries by running `missing.py` from giella-core
- **Divvun-runtime analysis**: Analyzes text using `divvun-runtime` with prebuilt `.drb` analyser files from the project build tree
- **Clipboard-based communication**: Uses clipboard with base64-encoded JSON for secure data transfer between sandbox and helper
- **UTF-8 support**: Correctly handles South Sámi and other Sámi languages with special characters

## Installation

### Simple installation (with Makefile)

```bash
make install
```

This copies `Divvun-SEE-helper.app` to `~/Applications/`.

### Manual installation

1. Copy `Divvun-SEE-helper.app` to `~/Applications/`
2. The first time you run the app, you must right-click and choose "Open" to approve the app (macOS security)

```bash
cp -R Divvun-SEE-helper.app ~/Applications/
```

### For developers: Code signing and notarization

To distribute the app without macOS security warnings, you need an Apple Developer account.

**1. Configure environment variables:**

Copy `.env.example` to `.env` and fill in the values:

```bash
cp .env.example .env
# Edit .env with your Apple Developer details
source .env
```

**2. Sign the app:**

```bash
make sign
# or directly: ./sign.sh
```

**3. Notarize the app:**

```bash
make notarize
# or directly: ./notarize.sh
```

Once notarization is complete, the app can be installed without security warnings.

## Configuration

The helper app automatically finds `missing.py` by checking these locations in order:

1. `$GTLANGS/giella-core/scripts/missing.py` (from JSON input)
2. `~/.divvun-see-helper-config` (optional config file)
3. `~/langtech/gut/giellalt/giella-core/scripts/missing.py`
4. `~/langtech/giellalt/giella-core/scripts/missing.py`

### Optional configuration

Create `~/.divvun-see-helper-config` to specify a custom path to giella-core and to enable logging:

```bash
# Custom path to giella-core (optional)
export GTCORE=/path/to/giella-core

# Enable debug logging (default is false)
export ENABLE_LOGGING=true
```

## Usage

The helper app is automatically launched by SubEthaEdit modes when you use features that require external tools:

- **LexC mode**: `⌃⌥⌘M` (Ctrl+Option+Cmd+M) for "Lexicalise missing"

### Divvun-runtime analysis

For the `divvun_analyze` operation to work, you need:

1. **divvun-runtime** installed (see System Requirements)
2. A **built analyser** (`.drb` file) in your language project

To build the analyser:
```bash
cd /path/to/lang-xxx
./configure --enable-analyser-tool --enable-tokenisers
make
```

The helper automatically searches for the newest `${LANGCODE}.drb` file in any `tools/analysers/` directory within your project, regardless of build directory names (searches up to 2 levels deep).

## macOS Service: Analyze Text System-Wide

Divvun-SEE-helper includes a macOS Service that lets you analyze selected text from any application - not just SubEthaEdit. This Quick Action appears in the Services menu when text is selected.

### Installing the Service

```bash
make install-service
```

This installs the Quick Action to your system. After installation, you'll see "Analyser tekst" (or "Analyze Text") in the Services menu when text is selected.

### Using the Service

1. Select text in any application
2. Right-click → Services → "Analyser tekst" (or use keyboard shortcut if configured)
3. The text will be analyzed and results will open in SubEthaEdit

### Configuring the Service

Set the default analysis language in `~/.divvun-see-helper-config`:

```bash
# Default language for text analysis service
export DEFAULT_ANALYSIS_LANG=sma

# Path to language repositories (required)
export GTLANGS=/path/to/langtech/gut
```

The service requires:
- A built `.drb` analyser file for the language (see Divvun-runtime analysis section above)
- SubEthaEdit installed in `/Applications/`

For more details, see [services/README.md](services/README.md).

### Uninstalling the Service

```bash
make uninstall-service
```

## Debugging

Debug logging is **disabled** by default to avoid unnecessary log files. To enable logging, add the following to `~/.divvun-see-helper-config`:

```bash
export ENABLE_LOGGING=true
```

When logging is enabled, the helper app will log all activity to:

```
~/divvun-see-helper-debug.log
```

Check this file when troubleshooting.

## Communication Protocol

The helper app communicates via clipboard using JSON format:

### Operation: analyze_missing

Analyzes words using `missing.py` from giella-core.

**Input (from SubEthaEdit):**
```json
{
  "operation": "analyze_missing",
  "lang": "sma",
  "gtlangs": "/path/to/lang-sma/..",
  "docname": "filename.lexc",
  "input_words_b64": "<base64-encoded words>"
}
```

**Output (from helper):**
```json
{
  "status": "success",
  "output": "<result from missing.py>"
}
```

### Operation: divvun_analyze

Analyzes text using `divvun-runtime` with prebuilt `.drb` analyser files.

**Input (from SubEthaEdit):**
```json
{
  "operation": "divvun_analyze",
  "lang": "sma",
  "gtlangs": "/path/to/lang-sma",
  "input_words_b64": "<base64-encoded words>"
}
```

**Output (from helper):**
```json
{
  "status": "success",
  "output": "<analysis result from divvun-runtime>"
}
```

### Error responses

On error:
```json
{
  "status": "error",
  "message": "Error message",
  "details": "Detailed error information"
}
```

## System Requirements

- macOS 10.15 or newer
- Python 3.9+ (included in Xcode Command Line Tools)
- HFST tools installed (via Homebrew or manually)
- giella-core (for missing.py)
- **divvun-runtime** (for divvun_analyze operation):
  ```bash
  brew install divvun/divvun/divvun-runtime
  ```

## Architecture

```
Divvun-SEE-helper.app/
├── Contents/
│   ├── Info.plist          # App metadata
│   └── MacOS/
│       ├── run-helper      # Wrapper that sets UTF-8 locale
│       └── divvun-see-helper  # Main script
```

### Components:

1. **run-helper**: Wrapper script that sets `LANG=en_US.UTF-8` and `LC_ALL=en_US.UTF-8` before running the main script
2. **divvun-see-helper**: Bash script that:
   - Reads JSON from clipboard
   - Base64-decodes input
   - Finds and runs missing.py
   - Constructs JSON response with escaped newlines
   - Writes result back to clipboard

## License

MIT - see LICENSE file.

## Contact

Divvun/Giellatekno
- GitHub: https://github.com/divvun
- Website: https://giellalt.github.io
