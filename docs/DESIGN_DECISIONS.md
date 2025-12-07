# Design Decisions

## 1. Native App vs Extension-Only

**Decision**: Hybrid approach (Chrome Extension + macOS App)

**Why**:
- **Chrome Extensions can't create floating windows** - They're constrained to the browser
- **Native apps have full OS control** - Can create borderless, always-on-top windows
- **Best UX**: True PIP experience that works across all desktop spaces

**Alternatives Considered**:
- Browser-only popup: Limited positioning, disappears when browser closes
- Web-based PIP API: Google blocks it for Meet
- Electron wrapper: Too heavy for this use case

## 2. DOM Parsing vs WebRTC

**Decision**: Parse DOM for active speaker detection

**Why**:
- **Simpler implementation** - Direct CSS class inspection
- **No media permissions** - Doesn't require microphone access
- **Proven reliable** - Class names stable across Meet updates
- **Lower CPU** - No audio processing needed

**Trade-off**: Doesn't work in background tabs (see LIMITATIONS.md)

**Alternative (WebRTC)**:
- Pros: Works in background, more accurate
- Cons: Requires mic permissions, complex audio level analysis, higher CPU

## 3. Smoothing Algorithm

**Decision**: Track 10 frames of history with 30% threshold

**Code**:
```typescript
private readonly historySize = 10;
private readonly threshold = 0.3;
```

**Why**:
- **Prevents flickering** - Single-frame active states ignored
- **Fast response** - Only 3/10 frames needed (300ms at 10fps)
- **Natural feel** - Matches Google Meet's own indicator timing

**Tuning**: Tested values from 0.2-0.5, 0.3 felt most responsive

## 4. Message Frequency (10fps)

**Decision**: Send updates every 100ms

**Why**:
- **Responsive enough** - Human eye perceives >10fps as smooth
- **Low bandwidth** - ~2-5 KB/s is negligible
- **CPU efficient** - Allows other processes to run

**Alternatives**:
- 60fps: Overkill, wastes CPU
- 5fps: Noticeable lag in speaker transitions
- On-change only: Complex event detection, can miss rapid changes

## 5. `setInterval` over `requestAnimationFrame`

**Decision**: Use `setInterval` for detection loop

**Why**:
- **Background tab support** - `setInterval` runs even when tab hidden
- **Consistent timing** - Not tied to display refresh rate
- **Previous issue**: RAF stopped completely in background

**Note**: Still limited by Google Meet's DOM updates (see LIMITATIONS.md)

## 6. Blocking PIP via API Override

**Decision**: Override `documentPictureInPicture.requestWindow()`

**Why**:
- **Clean approach** - Intercepts at API level
- **No UI changes** - Google Meet's PIP button just fails silently
- **Prevents dual PIP** - Our custom PIP doesn't conflict with browser's

**Alternatives**:
- CSS hiding: Brittle, can break with updates
- Monkey-patching Meet's code: Extremely fragile
- Allowing both: Confusing UX, wasted resources

## 7. Mute State Sync with MutationObserver

**Decision**: Watch `aria-label` changes on mic button

**Why**:
- **Accurate** - Directly monitors Meet's state
- **Bi-directional** - Catches changes from Meet UI, not just our extension
- **Accessible** - Uses semantic ARIA attributes

**Implementation**:
```typescript
mutationObserver.observe(document.body, {
  attributes: true,
  attributeFilter: ['aria-label']
});
```

## 8. Swift/SwiftUI for Native App

**Decision**: Modern Apple frameworks instead of Objective-C/AppKit

**Why**:
- **Declarative UI** - SwiftUI's reactivity perfect for this use case
- **Less code** - `@Published` + `@ObservedObject` handle state automatically
- **Modern** - Better long-term maintainability
- **Native look** - Matches macOS design language

**Trade-off**: macOS 11+ only (acceptable for modern systems)

## 9. Horizontal Speaker Layout

**Decision**: Horizontal strip instead of vertical stack or grid

**Why**:
- **Screen real estate** - Bottom of screen naturally horizontal
- **Readability** - Names don't get clipped
- **Scaling** - Grows naturally with speaker count
- **Aesthetic** - Feels like a dock/taskbar

**Previous**: Tried vertical, felt cramped and awkward

## 10. Always-Visible Mute Button

**Decision**: Mute button always shows, even with no speakers

**Why**:
- **Always accessible** - Primary use case
- **Window dragging** - Provides visual anchor
- **Consistency** - Window doesn't disappear unexpectedly

## 11. Transparent, Borderless Window

**Decision**: Fully transparent window with no chrome

**Why**:
- **Minimal distraction** - Only speaker content visible
- **Clean aesthetic** - Modern, polished look
- **Contextual** - Blends with desktop environment

**Implementation**:
```swift
window.styleMask = [.borderless]
window.backgroundColor = .clear
window.isOpaque = false
```

## 12. Text Backgrounds for Accessibility

**Decision**: Keep semi-transparent backgrounds behind speaker names

**Why**:
- **Legibility** - Works on any wallpaper/content
- **Accessibility** - WCAG contrast requirements
- **User request** - Explicitly asked to maintain

**Opacity**: 60% black tested across various backgrounds

## 13. Installation Script Approach

**Decision**: Manual `install.sh` instead of auto-installer

**Why**:
- **Security** - User sees exactly what's being installed
- **Flexibility** - Easy to modify paths/settings
- **Simplicity** - No complex installer logic
- **Development-friendly** - Quick iteration during development

**Trade-off**: Less polished for end users (acceptable for current scope)

## Future Considerations

### Not Implemented (Yet)

1. **WebRTC Audio Detection**: Would solve background tab limitation
2. **Screen Share Viewing**: Requires tab/screen capture APIs
3. **Cross-platform Native App**: Would need Electron or separate implementations
4. **Auto-update Mechanism**: Could use Chrome Web Store for extension
5. **User Preferences**: Could add settings UI for threshold, layout, etc.
