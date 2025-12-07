# Known Limitations

## 1. Background Tab Performance

**Issue**: Extension stops detecting speakers when you switch to a different tab.

**Why**: 
- Chrome throttles background tabs for performance
- Google Meet pauses DOM updates when tab is hidden
- The `.BlxGDf` active speaker class doesn't change in background
- Even with `setInterval` running, the data source (DOM) is stale

**Impact**:
- Native app shows last known speakers when tab is hidden
- Mute button state doesn't sync while tab is hidden
- Updates resume immediately when switching back to Meet tab

**Workarounds Attempted**:
1. ✗ Override `document.hidden` - Google Meet ignores this
2. ✗ Fake PIP window - Browser still throttles rendering
3. ✗ `setInterval` instead of `requestAnimationFrame` - Loop runs but DOM doesn't update

**Potential Solutions** (not implemented):
- Use WebRTC audio level monitoring instead of DOM parsing
- Require Meet tab to stay visible (UX constraint)
- Use Chrome's Tab Capture API with canvas rendering

## 2. DOM Selector Fragility

**Issue**: Google Meet can change CSS class names in updates.

**Current Selectors**:
```javascript
'.qg7mD.r6DyN.xm86Be.JBY0Kc.eXUaib.KXY1yb' // Speaker tile
'.BlxGDf' // Active speaker indicator
'[aria-label="Call controls"]' // Control bar
```

**Why**: These are Google's internal class names, not documented APIs.

**Mitigation**:
- Tested across multiple Meet updates (stable so far)
- Fallback to generic selectors where possible
- User can report breakage via console logs

## 3. High-Resolution Avatars

**Issue**: Sometimes avatars appear low-resolution.

**Why**: Google Meet loads different quality images based on:
- Network conditions
- Screen size
- Number of participants

**Current Logic**:
```javascript
// Try high-res class first
img = el.querySelector('.SOQwsf') 
// Fallback to 2nd image
|| el.querySelectorAll('img')[1]
// Last resort: 1st image
|| el.querySelector('img')
```

**Limitation**: Can't guarantee high-res in all scenarios.

## 4. Screen Share Detection

**Issue**: When someone shares screen, we show their avatar instead of the screen content.

**Why**: By design - we extract static images (avatars), not live video streams.

**Rationale**: 
- Capturing live video would require screen/tab capture APIs
- Significantly increases complexity and CPU usage
- Current focus is on speaker identification, not content viewing

## 5. Mute Button Precision

**Issue**: Rarely, mute button might target wrong participant in large calls.

**Why**: Multiple microphone buttons exist in the DOM:
- Your own mic toggle
- Device selection dropdown
- Host controls for other participants

**Mitigation**:
- Strict selector: `[aria-label="Call controls"] button[data-is-muted]`
- Only matches the main toggle button
- Tested with 10+ participants

## 6. PIP Blocking Side Effects

**Issue**: Blocking PIP might interfere with other browser extensions.

**Why**: We override `documentPictureInPicture` globally.

**Impact**: Low - only affects Google Meet page, not other sites.

## 7. Window Dragging on Hover

**Issue**: Dragging can be unintuitive if you accidentally click the background.

**Why**: Entire window background is draggable for UX convenience.

**Feature**: Intentional - allows easy repositioning even with no speakers.

## 8. Native Messaging Setup

**Issue**: Requires manual installation script and extension ID configuration.

**Why**: Chrome's native messaging security model.

**Steps Required**:
1. Build native app
2. Run `install.sh` to copy manifest
3. Update extension ID in `.env`
4. Reload extension

**Future**: Could automate via post-install scripts.

## 9. macOS Only

**Issue**: Native app only works on macOS.

**Why**: Built with Swift/SwiftUI which are Apple-only.

**Alternatives** (not implemented):
- Electron wrapper (cross-platform but heavier)
- Separate Windows/Linux implementations
- Web-based PIP using Chrome extension APIs only

## Browser Compatibility

**Supported**: Chrome/Chromium browsers with native messaging support

**Not Supported**:
- Firefox (different native messaging protocol)
- Safari (no extension support for Google Meet)
- Mobile browsers (no native messaging)
