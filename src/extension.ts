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

	constructor() {
		this.connect();
	}

	private connect() {
		try {
			console.log(`Connecting to background script...`);

			// Connect to background script which proxies to native host
			this.port = chrome.runtime.connect({ name: 'meet-pip-content' });

			this.port.onMessage.addListener((msg) => {
				console.log('Received message from native app (via background):', msg);
				// Handle messages from Swift app if needed (e.g. "Close PIP")
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

			const speakers = detector.detect();
			// Send data to Native App
			// Structure: { type: "update", speakers: [{avatarUrl: "...", name: "..."}] }
			try {
				this.port.postMessage({ type: 'update', speakers });
			} catch (e) {
				console.error('Error posting message:', e);
				this.isConnected = false;
			}

			// Check for invalidation to avoid zombie scripts
			if (!chrome.runtime?.id) {
				console.log('Extension context invalidated. Stopping loop.');
				this.isConnected = false;
				this.stopLoop();
				removeControls();
				return;
			}

			// Loop frequency: 30fps is overkill for just data. 10fps is enough.
			// But requestAnimationFrame is 60fps. Lower frequency might be better but rAF is simplest.
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

	public reconnect() {
		if (!this.isConnected) {
			this.connect();
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
	btn.innerText = 'Start Native PIP';
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
		if (bridge) {
			bridge.reconnect();
		} else {
			init();
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
