# WebRTC Audio Detection Approach

## Concept Overview

Instead of parsing the DOM for visual indicators (`.BlxGDf` class), we analyze the actual WebRTC audio streams to detect who's speaking based on audio volume levels.

## How It Works

### 1. Access WebRTC Peer Connections
Google Meet uses WebRTC for audio/video transmission. We can intercept these connections:

```javascript
// Hook into RTCPeerConnection creation
const OriginalRTCPeerConnection = window.RTCPeerConnection;
window.RTCPeerConnection = function(...args) {
  const pc = new OriginalRTCPeerConnection(...args);
  // Monitor this connection
  monitorPeerConnection(pc);
  return pc;
};
```

### 2. Get Audio Tracks
Each participant has an audio track in the peer connection:

```javascript
function monitorPeerConnection(pc) {
  pc.addEventListener('track', (event) => {
    if (event.track.kind === 'audio') {
      // Analyze this audio stream
      analyzeAudioTrack(event.track, event.streams[0]);
    }
  });
}
```

### 3. Analyze Audio Levels
Use Web Audio API to measure volume:

```javascript
function analyzeAudioTrack(track, stream) {
  const audioContext = new AudioContext();
  const source = audioContext.createMediaStreamSource(stream);
  const analyzer = audioContext.createAnalyser();
  analyzer.fftSize = 256;
  
  source.connect(analyzer);
  
  const dataArray = new Uint8Array(analyzer.frequencyBinCount);
  
  // Check audio level periodically
  setInterval(() => {
    analyzer.getByteFrequencyData(dataArray);
    const average = dataArray.reduce((a, b) => a + b) / dataArray.length;
    
    if (average > SPEAKING_THRESHOLD) {
      // This person is speaking!
    }
  }, 100);
}
```

### 4. Match Tracks to Participants
The tricky part - correlating audio tracks with participant identities:

**Option A: Mid-layer correlation**
```javascript
// WebRTC tracks have "mid" (media ID) that we can match to DOM elements
const mid = event.transceiver.mid;
// Search DOM for elements referencing this mid
```

**Option B: Stream metadata**
```javascript
// Parse SDP (Session Description Protocol) to get track-to-user mapping
pc.addEventListener('track', (event) => {
  const streamId = event.streams[0].id;
  // Match streamId to participant data
});
```

**Option C: Timing correlation**
```javascript
// When DOM shows someone speaking, note which audio track is active
// Build a mapping over time
```

## Advantages ✅

### 1. Works in Background Tabs
- Audio analysis continues even when tab is hidden
- Chrome doesn't throttle Web Audio API
- No dependency on visual rendering

### 2. More Accurate
- Detects actual speech, not just visual indicators
- Can distinguish between loud vs quiet speakers
- Works even if Meet's UI lags

### 3. Resilient to UI Changes
- No reliance on CSS class names
- Google Meet can redesign UI without breaking detection
- Works across different Meet layouts (grid, presentation, etc.)

### 4. Better Smoothing
- Can use audio envelope detection
- Natural speech patterns for better transitions
- Eliminate false positives from brief noises

## Challenges ⚠️

### 1. Participant Identification
**Hard problem**: Matching audio streams to names/avatars

- WebRTC tracks don't include participant names
- Need to correlate stream IDs with DOM elements
- Mapping could break if Meet changes internal structure

**Mitigation**:
- Build mapping when tab is visible
- Cache participant audio fingerprints
- Fallback to "Unknown Speaker N" if mapping fails

### 2. Privacy Concerns
**Issue**: Accessing raw audio data feels invasive

- Users might be concerned about mic access
- Need clear disclosure in extension description
- Must ensure we never record/transmit audio

**Mitigation**:
- Only analyze volume levels, not audio content
- Explicitly state "no recording" in permissions
- Open source code for transparency

### 3. Implementation Complexity
**Significantly more code**:
- ~500-800 lines vs current ~200
- Need Web Audio API expertise
- Complex debugging (audio issues are hard to diagnose)

### 4. Performance
**CPU usage**:
- FFT analysis every 100ms per participant
- 10 participants = 10 audio analyzers running
- Could drain battery on laptops

**Mitigation**:
- Use smaller FFT size (128 instead of 2048)
- Pause analysis when window is minimized
- Optimize using OfflineAudioContext where possible

### 5. Audio Permissions
**Browser requirement**:
- Might need to request microphone permission
- Users could deny, breaking the feature
- Permission prompt could scare users

**Note**: Analyzing *remote* tracks shouldn't require mic permission, but browser behavior varies

## Implementation Strategy

### Phase 1: Proof of Concept
1. Hook RTCPeerConnection
2. Enumerate audio tracks
3. Basic volume detection
4. Log results to console

### Phase 2: Participant Mapping
1. Build stream-to-DOM mapping
2. Extract participant names
3. Handle participant join/leave
4. Fallback to "Unknown" for unmapped streams

### Phase 3: Integration
1. Replace detector.ts with audio-detector.ts
2. Keep DOM parsing as fallback
3. Hybrid approach: audio for detection, DOM for names/avatars

### Phase 4: Polish
1. Optimize performance
2. Add user preferences (sensitivity threshold)
3. Handle edge cases (network issues, muted participants)

## Hybrid Approach (Recommended)

**Best of both worlds**:
- Use **WebRTC for detection** (who's speaking)
- Use **DOM for metadata** (names, avatars, participant list)

```typescript
class HybridDetector {
  private audioDetector: WebRTCAudioDetector;
  private domParser: DOMSpeakerParser;
  
  detect(): SpeakerData[] {
    // Get active speaker IDs from audio
    const activeStreamIds = this.audioDetector.getActiveSpeakers();
    
    // Get metadata from DOM
    const participants = this.domParser.getAllParticipants();
    
    // Match and combine
    return participants.filter(p => 
      activeStreamIds.includes(p.streamId)
    );
  }
}
```

**Benefits**:
- ✅ Works in background (audio detection)
- ✅ Has names/avatars (DOM parsing)
- ✅ Falls back gracefully if one method fails

## Estimated Effort

- **Simple WebRTC detection**: 2-3 days
- **Participant mapping**: 3-5 days  
- **Full integration + testing**: 2-3 days
- **Polish + edge cases**: 2-3 days

**Total**: ~2 weeks for production-ready implementation

## Alternative: Simpler Audio Approach

**Chrome Tab Capture API**:
```javascript
chrome.tabCapture.capture({audio: true}, (stream) => {
  // Analyze the entire call's audio
  // Detect speech presence (not individual speakers)
});
```

**Pros**: Much simpler, no peer connection hooking  
**Cons**: Can't distinguish individual speakers, requires tab capture permission

## Recommendation

**For your use case**, I'd suggest:

1. **Start with hybrid approach** - keeps current DOM detection, adds audio as enhancement
2. **Incremental migration** - audio detection first, participant mapping second
3. **Feature flag** - let users toggle between methods

This way:
- Current functionality stays working
- Background tab support added gradually
- Lower risk of breaking existing features

Want me to create a detailed implementation plan or start with a proof-of-concept?
