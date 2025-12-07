# Communication Protocol

## Native Messaging Format

### Message Structure
All messages use JSON with a 4-byte little-endian length prefix (Chrome's native messaging protocol).

```
[4 bytes: message length][JSON payload]
```

## Message Types

### Extension → Native App

#### 1. Speaker Update
**Sent**: Every 100ms (10fps)  
**Purpose**: Update active speaker list

```json
{
  "type": "update",
  "speakers": [
    {
      "avatarUrl": "https://...",
      "name": "Speaker Name"
    }
  ]
}
```

#### 2. Mute State Sync
**Sent**: When Google Meet's mute button state changes  
**Purpose**: Keep native app's mute button in sync

```json
{
  "type": "mute-state",
  "isMuted": true
}
```

### Native App → Extension

#### 1. Mute Toggle
**Sent**: When user clicks mute button in native app  
**Purpose**: Toggle microphone in Google Meet

```json
{
  "type": "toggle-mute"
}
```

## Implementation Details

### Extension Side (TypeScript)

**Sending** (in `extension.ts`):
```typescript
this.port.postMessage({ type: 'update', speakers });
```

**Receiving** (in `extension.ts`):
```typescript
this.port.onMessage.addListener((msg) => {
  if (msg.type === 'toggle-mute') {
    this.toggleMute();
  }
});
```

### Background Script Proxy (TypeScript)

Routes messages bidirectionally:
```typescript
// Extension → Native
port.onMessage.addListener((msg) => {
  nativePort.postMessage(msg);
});

// Native → Extension
nativePort.onMessage.addListener((msg) => {
  port.postMessage(msg);
});
```

### Native App Side (Swift)

**Reading** (in `InputListener.swift`):
```swift
let lengthData = input.readData(ofLength: 4)
let length = UInt32(littleEndian: lengthData.load(as: UInt32.self))
let jsonData = input.readData(ofLength: Int(length))
let message = try JSONSerialization.jsonObject(with: jsonData)
```

**Sending** (in `InputListener.swift`):
```swift
var length = UInt32(jsonData.count)
FileHandle.standardOutput.write(Data(bytes: &length, count: 4))
FileHandle.standardOutput.write(jsonData)
```

## Error Handling

### Connection Loss
- **Extension**: Detects via `port.onDisconnect`, stops detection loop
- **Native App**: Reads return EOF (<4 bytes), breaks loop

### Invalid Messages
- **Extension**: Try/catch around `postMessage`, logs errors
- **Native App**: JSON parse failures are silently ignored

### Extension Reload
- **Extension**: Checks `chrome.runtime.id` to detect context invalidation
- **Native App**: Connection breaks, app can continue running for next connection

## Performance Considerations

### Update Frequency
- **10fps (100ms)**: Balance between responsiveness and CPU usage
- **Throttling**: Previously used `requestAnimationFrame` but switched to `setInterval` to support background tabs

### Message Size
- **Typical size**: ~200-500 bytes per update (2-3 speakers)
- **Bandwidth**: ~2-5 KB/s at 10fps
- **Impact**: Negligible on modern systems
