# Meet PIP Architecture

## Overview
Meet PIP is a Chrome extension + native macOS app that provides a custom Picture-in-Picture experience for Google Meet, showing active speakers in a floating window.

## System Components

### 1. Chrome Extension (TypeScript)
**Location**: `/src`

#### Components:
- **`extension.ts`**: Content script that runs on Google Meet pages
  - Manages native messaging connection
  - Detects active speakers via DOM inspection
  - Monitors mute state
  - Blocks Google Meet's native PIP
  
- **`detector.ts`**: Speaker detection logic
  - Scans DOM for participant tiles
  - Identifies active speakers using CSS classes
  - Implements smoothing algorithm to prevent flickering
  - Extracts speaker names and avatar URLs

- **`background.ts`**: Service worker
  - Proxies messages between content script and native app
  - Manages native messaging host connection

- **`pip-blocker.js`**: Injected page script
  - Overrides browser PIP APIs
  - Prevents Google Meet from opening native PIP windows

### 2. Native macOS App (Swift/SwiftUI)
**Location**: `/meet-pip/meetpip`

#### Components:
- **`meetpipApp.swift`**: App entry point
  - Configures floating, borderless window
  - Initializes InputListener on startup

- **`InputListener.swift`**: Native messaging handler
  - Reads JSON from stdin (Chrome's native messaging pipe)
  - Parses speaker updates and mute state messages
  - Sends mute toggle commands to extension
  - Publishes data to SwiftUI views

- **`ContentView.swift`**: UI layer
  - Displays speaker avatars and names
  - Shows mute button with state synchronization
  - Implements window dragging
  - Dynamically resizes based on speaker count

## Data Flow

```
Google Meet DOM
    ↓
detector.ts (scans for .BlxGDf class)
    ↓
extension.ts (every 100ms)
    ↓
background.ts (proxy)
    ↓
Chrome Native Messaging (stdin/stdout)
    ↓
InputListener.swift
    ↓
ContentView.swift (displays UI)
```

### Reverse Flow (Mute Toggle)
```
ContentView.swift (button click)
    ↓
InputListener.swift (JSON to stdout)
    ↓
Chrome Native Messaging
    ↓
background.ts (proxy)
    ↓
extension.ts (clicks mic button)
    ↓
Google Meet UI
```

## Key Technologies

### Extension
- **TypeScript** for type safety
- **Vite** for bundling
- **Chrome Native Messaging API** for native communication
- **MutationObserver** for DOM monitoring

### Native App
- **Swift/SwiftUI** for modern macOS UI
- **AsyncImage** for remote avatar loading
- **Combine** for reactive state management
- **FileHandle** for stdin/stdout communication

## Build System
- **npm** for extension dependencies
- **Xcode/xcodebuild** for native app compilation
- **Makefile** for coordinated builds
