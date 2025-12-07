import { SpeakerDetector } from './detector';

const detector = new SpeakerDetector();

// Critical: Inject the blocker script as early as possible (at document_start)
// to ensure we override the prototype before Google Meet code runs.
function injectBlocker() {
	try {
		console.log('Injecting PIP blocker...');
		const script = document.createElement('script');
		script.src = chrome.runtime.getURL('pip-blocker.js');
		(document.head || document.documentElement).appendChild(script);
		script.onload = () => {
			script.remove();
		};
	} catch (e) {
		console.error('Failed to inject PIP blocker:', e);
	}
}

// Inject immediately!
injectBlocker();


class NativeBridge {
	private port: chrome.runtime.Port | null = null;
	private isConnected = false;
	private loopId: number = 0;

	private muteObserver: MutationObserver | null = null;
	private lastUpdate = 0;

	constructor() {
		this.connect();
		this.setupMuteObserver();
	}

	private setupMuteObserver() {
		if (this.muteObserver) return;

		// Observer for Mute State
		// Google Meet Mute Button changes aria-label: "Turn off microphone" (unmuted) <-> "Turn on microphone" (muted)
		const observerConfig = { attributes: true, subtree: true, attributeFilter: ['aria-label', 'data-is-muted'] };

		this.muteObserver = new MutationObserver((mutations) => {
			for (const mutation of mutations) {
				const target = mutation.target as HTMLElement;
				if (this.isMicButton(target)) {
					this.checkMuteState(target);
				}
			}
		});

		const controlsBar = document.body; // Observing body is easiest to catch the footer
		this.muteObserver.observe(controlsBar, observerConfig);

		// Initial check
		setTimeout(() => {
			const micBtn = this.findMicButton();
			if (micBtn) this.checkMuteState(micBtn);
		}, 2000); // Give time for UI to load
	}

	private findMicButton(): HTMLElement | null {
		return document.querySelector('button[aria-label*="microphone"], button[aria-label*="Microphone"]') as HTMLElement;
	}

	private isMicButton(el: HTMLElement): boolean {
		const label = el.getAttribute('aria-label');
		return (label && label.toLowerCase().includes('microphone')) || false;
	}

	private checkMuteState(btn: HTMLElement) {
		const label = btn.getAttribute('aria-label') || '';
		// "Turn on microphone" means it is CURRENTLY MUTED
		const isMuted = label.toLowerCase().includes('turn on');

		console.log(`[MeetPIP] Mute Sync: Label="${label}" -> Muted=${isMuted}`);

		if (this.isConnected && this.port) {
			this.port.postMessage({
				type: 'mute-state',
				isMuted: isMuted
			});
		}
	}

	private connect() {
		try {
			console.log(`Connecting to background script...`);

			// Connect to background script which proxies to native host
			this.port = chrome.runtime.connect({ name: 'meet-pip-content' });

			this.port.onMessage.addListener((msg) => {
				console.log('Received message from native app (via background):', msg);
				if (msg.type === 'toggle-mute') {
					this.toggleMute();
				}
			});

			this.port.onDisconnect.addListener(() => {
				console.log('Disconnected from background script');
				if (chrome.runtime.lastError) {
					console.warn('Background Connection Error:', chrome.runtime.lastError.message);
				}
				this.isConnected = false;
				this.stopLoop();
			});

			this.isConnected = true;
			this.startLoop();
		} catch (e) {
			console.error('Failed to connect to background script:', e);
		}
	}

	private startLoop() {
		if (this.loopId) return;

		const loop = () => {
			if (!this.isConnected || !this.port) return;

			// Validate extension context
			if (!chrome.runtime?.id) {
				console.log('Extension context invalidated. Stopping loop.');
				this.isConnected = false;
				this.stopLoop();
				removeControls();
				return;
			}

			// Throttle to ~10fps (every 100ms)
			const now = Date.now();
			if (now - this.lastUpdate > 100) {
				this.lastUpdate = now;

				const speakers = detector.detect();
				// Send data to Native App
				try {
					this.port.postMessage({ type: 'update', speakers });
				} catch (e) {
					console.error('Error posting message:', e);
					this.isConnected = false;
				}
			}

			this.loopId = requestAnimationFrame(loop);
		};
		this.loopId = requestAnimationFrame(loop);
	}

	private stopLoop() {
		if (this.loopId) {
			cancelAnimationFrame(this.loopId);
			this.loopId = 0;
		}
	}

	public disconnect() {
		if (this.isConnected) {
			console.log('Disconnecting from native bridge...');
			this.isConnected = false;
			this.stopLoop();
			if (this.port) {
				this.port.disconnect();
				this.port = null;
			}
			if (this.muteObserver) {
				this.muteObserver.disconnect();
				this.muteObserver = null;
			}
		}
	}

	public reconnect() {
		if (!this.isConnected) {
			this.connect();
			this.setupMuteObserver();
		}
	}

	private toggleMute() {
		// Attempt to toggle mute by clicking the microphone button
		// Google Meet buttons usually have aria-labels containing "microphone"
		const micButton = this.findMicButton();
		if (micButton) {
			console.log('Toggling mute via button click');
			micButton.click();
			// Optimistic update
			// this.checkMuteState(micButton); // Logic is async due to react, observer should catch it
		} else {
			// Fallback: Dispatch Command+D (Mac) / Control+D (Windows/Linux)
			console.log('Toggling mute via keyboard shortcut');
			const isMac = (navigator.userAgentData?.platform === 'macOS') || (navigator.platform.toUpperCase().indexOf('MAC') >= 0);
			document.body.dispatchEvent(new KeyboardEvent('keydown', {
				key: 'd',
				code: 'KeyD',
				metaKey: isMac,
				ctrlKey: !isMac,
				bubbles: true
			}));
		}
	}
}

// Logic to start the bridge
// We ideally want this to start when the user enters a meeting.
// For now, we auto-start when the content script loads (which is on meeting load).
let bridge: NativeBridge | null = null;

function init() {
	console.log('Initializing Native Bridge...');
	bridge = new NativeBridge();
}

// Add a simple UI button to "Reconnect" or "Start Native PIP"
const BUTTON_ID = 'meet-pip-control-btn';

function removeControls() {
	const existing = document.getElementById(BUTTON_ID);
	if (existing) {
		existing.remove();
	}
}

function addControls() {
	removeControls(); // Ensure only one button exists

	const btn = document.createElement('button');
	btn.id = BUTTON_ID;
	// Since we auto-connect in init(), the state starts as connected/active.
	// If init() hasn't run yet, it will run shortly. 
	// To be safe, we default to "Stop" if bridge exists, or "Start" if not, but init() is called immediately after.
	// Actually, easier: We init() at bottom.
	const isRunning = bridge && bridge['isConnected'];
	btn.innerText = isRunning ? 'Stop Native PIP' : 'Start Native PIP';
	btn.style.position = 'fixed';
	btn.style.bottom = '80px';
	btn.style.right = '20px';
	btn.style.zIndex = '9999';
	btn.style.padding = '10px 20px';
	btn.style.background = '#202124';
	btn.style.color = '#fff';
	btn.style.border = '1px solid #5f6368';
	btn.style.borderRadius = '24px';
	btn.style.cursor = 'pointer';
	btn.style.fontFamily = '"Google Sans",Roboto,Arial,sans-serif';
	btn.style.fontWeight = '500';

	btn.onclick = () => {
		if (bridge && bridge['isConnected']) {
			bridge.disconnect();
			btn.innerText = 'Start Native PIP';
		} else {
			if (bridge) {
				bridge.reconnect();
			} else {
				init();
			}
			btn.innerText = 'Stop Native PIP';
		}
	};

	document.body.appendChild(btn);
}

// Cleanup any potential leftovers from previous injections immediately
removeControls();

if (document.body) {
	addControls();
	init();
} else {
	window.addEventListener('DOMContentLoaded', () => {
		addControls();
		init();
	});
}
