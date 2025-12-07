# Development Setup

## Prerequisites

- **macOS** 11+
- **Xcode** 15+ with Command Line Tools
- **Node.js** 18+ and npm
- **Google Chrome** or Chromium-based browser

## Initial Setup

### 1. Clone and Install Dependencies

```bash
cd meet-pip
npm install
```

### 2. Configure Environment

Create `.env` file:
```bash
EXTENSION_ID=your_extension_id_here
```

(You'll get the extension ID after loading the extension in Chrome)

### 3. Build Extension

```bash
npm run build
```

Output: `/dist` folder ready to load in Chrome

### 4. Build Native App

```bash
make build-app
```

Or with custom code signing:
```bash
TEAM_ID=YOUR_TEAM_ID make build-app
```

Output: `/meet-pip/DerivedData/Build/Products/Debug/meetpip.app`

### 5. Install Native Messaging Host

```bash
cd native-setup
./install.sh
```

This copies the manifest to:
`~/Library/Application Support/Google/Chrome/NativeMessagingHosts/`

### 6. Load Extension in Chrome

1. Go to `chrome://extensions`
2. Enable "Developer mode"
3. Click "Load unpacked"
4. Select the `/dist` folder
5. Copy the extension ID
6. Update `.env` file with the ID
7. Re-run `./install.sh` to update manifest
8. Reload extension

## Development Workflow

### Watch Mode (Extension)

```bash
npm run dev
```

Auto-rebuilds on file changes to `/src`

### Iterating on Native App

```bash
# Make changes to Swift files
make build-app
# App binary is automatically updated
# Chrome will use new version on next native messaging connection
```

### Testing

1. Join a Google Meet call
2. Native app should launch automatically
3. Check Chrome DevTools console for `[MeetPIP]` logs
4. Check background page: `chrome://extensions` → "Inspect background page"

## Project Structure

```
meet-pip/
├── src/                    # Extension TypeScript source
│   ├── extension.ts        # Main content script
│   ├── detector.ts         # Speaker detection
│   ├── background.ts       # Service worker
│   └── global.d.ts         # Type definitions
├── public/                 # Extension static files
│   ├── manifest.json
│   └── pip-blocker.js      # Injected page script
├── meet-pip/meetpip/       # Native macOS app
│   ├── meetpipApp.swift    # App entry
│   ├── InputListener.swift # Native messaging
│   └── ContentView.swift   # UI
├── native-setup/           # Installation files
│   ├── install.sh
│   └── com.meetpip.app.json
├── docs/                   # Documentation
├── dist/                   # Built extension (gitignored)
└── DerivedData/            # Xcode build output (gitignored)
```

## Build Commands

### Extension
```bash
npm run build        # Production build
npm run dev          # Watch mode
```

### Native App
```bash
make build-app       # Debug build
make clean           # Clean build artifacts
```

### Combined
```bash
npm run build && make build-app
```

## Debugging

### Extension Console Logs

**Content Script**: Right-click page → Inspect
**Background Script**: `chrome://extensions` → "Inspect background page"

Look for:
- `[MeetPIP]` logs from pip-blocker.js
- `Connecting to background script...` from extension.ts
- `Content script -> Native app:` from background.ts

### Native App Logs

The app writes to stderr which Chrome captures. Check background console for:
- `[MeetPIP 12:34:56] InputListener started`
- `[MeetPIP 12:34:56] Updating speakers count: 2`

### Common Issues

**"Native host not found"**
- Run `install.sh` again
- Check manifest path: `~/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.meetpip.app.json`
- Verify binary path in manifest matches actual location

**"Speakers not detected"**
- Check console for selector errors
- Google Meet might have updated CSS classes
- Verify selector: `.qg7mD.r6DyN.xm86Be.JBY0Kc.eXUaib.KXY1yb`

**"Mute button not syncing"**
- Check for `[MeetPIP] Mute Sync:` logs
- Selector might be broken: `[aria-label="Call controls"] button[data-is-muted]`

## Code Signing

### Development

Default: Ad-hoc signing (works for local development)

### Distribution (Future)

1. Get Apple Developer account
2. Create certificate
3. Update `TEAM_ID` in Makefile
4. Build with: `TEAM_ID=ABC123 make build-app`

## Clean Build

```bash
# Extension
rm -rf dist/ node_modules/
npm install
npm run build

# Native App
make clean
make build-app

# Both
make clean && rm -rf dist/ node_modules/ && npm install && npm run build && make build-app
```
