# Release Assets for v1.1.0

Upload these files to the GitHub release page:

## 1. Main Application Bundle

**Divvun-SEE-helper-v1.1.0.zip** (4.2 KB)
- Contains the complete `Divvun-SEE-helper.app` bundle
- Ready to install to `~/Applications/`
- SHA256: `4ac8a4f0e70bc03a7421e0949a209704851b29f866113816253804f4caeb02f0`

**Divvun-SEE-helper-v1.1.0.zip.sha256**
- Checksum file for verification

## 2. macOS Services (Optional)

**Divvun-SEE-helper-services-v1.1.0.zip** (14 KB)
- Contains both macOS Services:
  - Analyze Text.workflow
  - Draw Dependency Tree.workflow
- Plus installation scripts:
  - install-service.sh
  - uninstall-service.sh
  - analyze-text-service.sh
  - draw-dependency-tree-service.sh
- Plus services/README.md documentation
- SHA256: `47695c78467ce7486c85afca895915f2ade1a9b945f62cb999a69ac50f85d68d`

**Divvun-SEE-helper-services-v1.1.0.zip.sha256**
- Checksum file for verification

## Installation Instructions (for users)

### Quick Install (Main App)
```bash
unzip Divvun-SEE-helper-v1.1.0.zip
mv Divvun-SEE-helper.app ~/Applications/
```

### With Services
```bash
# Extract and enter the repository
unzip Divvun-SEE-helper-v1.1.0.zip
cd divvun-see-helper

# Install app and services
make install
make install-service
```

Or use the services zip separately:
```bash
unzip Divvun-SEE-helper-services-v1.1.0.zip
cd services
./install-service.sh
```

## Verification

Users can verify downloads with:
```bash
shasum -a 256 -c Divvun-SEE-helper-v1.1.0.zip.sha256
shasum -a 256 -c Divvun-SEE-helper-services-v1.1.0.zip.sha256
```
