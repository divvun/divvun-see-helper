# Version History

## Version 1.1.1 (2026-02-13)

### Bug Fixes

**Critical fix for service installation**
- Fixed missing service scripts that caused "No such file or directory" errors when using services
- Service scripts now reside in `Divvun-SEE-helper.app/Contents/MacOS/` as part of the app bundle
- Eliminated code duplication - scripts exist in one location only
- Simplified installation process - `make install` now installs a complete, self-contained app

**Architecture improvement:**
- Service scripts (`analyze-text-service.sh` and `draw-dependency-tree-service.sh`) are now part of the app bundle itself
- No longer duplicated in `services/` directory
- Installation process simplified - no copying needed, app bundle is complete

This fix resolves the issue where users would see errors like:
```
/Users/username/Applications/Divvun-SEE-helper.app/Contents/MacOS/analyze-text-service.sh: No such file or directory
```

**Users affected by v1.1.0**: Please update to v1.1.1 by running `make install` to get the fixed app bundle.

---

## Version 1.1.0 (2026-02-12)

### New Features

#### System-Wide macOS Services
Two new macOS Services (Quick Actions) that work with selected text in any application:

1. **Analyze Text** - Morphological and syntactic text analysis
   - Select text in any app → Right-click → Services → Analyze Text
   - Analyzes text using divvun-runtime with .drb analyser files
   - Opens results in SubEthaEdit with vislcg3 format
   - Shows lemma, POS tags, morphological features, and dependency relations

2. **Draw Dependency Tree** - Visual dependency tree generation
   - Select text in any app → Right-click → Services → Draw Dependency Tree
   - Creates visual dependency graph as PNG image
   - Uses cg-dep2dot.py and Graphviz to generate tree diagram
   - Opens in Preview with copy capability

Both services:
- Respect language settings from `~/.divvun-see-helper-config`
- Use the same analyser files as SubEthaEdit integration
- Work system-wide in any macOS application

#### Debug Logging
Comprehensive debug logging for troubleshooting, controlled by `ENABLE_LOGGING=true` in config:
- Timestamped log entries with service identification
- Full paths to all tools used (divvun-runtime, cg-dep2dot.py, dot, etc.)
- Language and GTLANGS configuration
- File operations with sizes and paths
- Response status and error conditions
- Logs written to `~/divvun-see-helper-debug.log`

Helps diagnose issues like:
- Wrong analyser files being used
- Missing dependencies
- PATH configuration problems
- Service execution flow

### Improvements

#### Analyser File Search
- Increased search depth from 3 to 5 directory levels
- Now correctly finds newest .drb files in build directories like `lang-sme/bygg/analyse/tools/analysers/`
- Fixes issue where old analyser files were used instead of newly built ones

#### Service Script Renaming
- Renamed `analyze-dependency-tree-service.sh` to `draw-dependency-tree-service.sh` for clarity

### Installation
```bash
make install              # Install helper app
make install-service      # Install both macOS Services
```

### Configuration
Services can be configured via `~/.divvun-see-helper-config`:
```bash
export DEFAULT_ANALYSIS_LANG="sme"
export GTLANGS="$HOME/langtech/gut/giellalt"
export GTCORE="$HOME/langtech/gut/giellalt/giella-core"
export ENABLE_LOGGING=true  # Optional: enable debug logging
```

---

## Version 1.0.0

Initial release with SubEthaEdit integration:
- LexC analysis for missing lexicon entries
- Clipboard-based JSON communication protocol
- UTF-8 support for Sámi languages
- Optional logging functionality
