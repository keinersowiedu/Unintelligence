# Apple Intelligence Remover

A macOS SwiftUI app to disable Apple Intelligence and reclaim 7-10GB+ of storage.

## Build & Run (on a Mac)

```bash
cd "Apple Intelegent Remover"
swift build
swift run
```

Or open in Xcode:
```bash
open Package.swift
```

Then press **⌘+R** to run.

## Features

- **Scan** — Finds Apple Intelligence model files on your system
- **Disable** — Turns off Apple Intelligence via system preferences
- **Remove** — Deletes model files (with admin privilege escalation)
- **Recovery Script** — Generates a bash script for Recovery Mode removal
- **Recovery Guide** — Step-by-step instructions for removing SIP-protected files

## Important Notes

- Some AI model files are protected by **System Integrity Protection (SIP)** and can only be removed from **Recovery Mode**
- The app includes a "Save Recovery Script" feature that generates a ready-to-use bash script
- Disabling Apple Intelligence prevents re-downloading of models
- macOS 14+ (Sonoma) required
