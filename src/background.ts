const HOST_NAME = 'com.meetpip.app';

console.log('Background script loaded');

// On install or update, inject the content script into existing Meet tabs
chrome.runtime.onInstalled.addListener(async () => {
	console.log('Extension installed/updated. Injecting into existing tabs...');
	const tabs = await chrome.tabs.query({ url: 'https://meet.google.com/*' });
	for (const tab of tabs) {
		if (tab.id) {
			try {
				await chrome.scripting.executeScript({
					target: { tabId: tab.id },
					files: ['content-script.js']
				});
				console.log(`Injected content script into tab ${tab.id}`);
			} catch (err) {
				console.error(`Failed to inject into tab ${tab.id}:`, err);
			}
		}
	}
});

chrome.runtime.onConnect.addListener((port) => {
	if (port.name === 'meet-pip-content') {
		console.log('Connected to content script');

		let nativePort: chrome.runtime.Port | null = null;

		try {
			console.log(`Connecting to native host: ${HOST_NAME}`);
			nativePort = chrome.runtime.connectNative(HOST_NAME);

			nativePort.onMessage.addListener((msg) => {
				console.log('Received message from native app:', msg);
				port.postMessage(msg);
			});

			nativePort.onDisconnect.addListener(() => {
				console.log('Native host disconnected');
				if (chrome.runtime.lastError) {
					console.warn('Native Connection Error:', chrome.runtime.lastError.message);
				}
				port.disconnect();
			});

			port.onMessage.addListener((msg) => {
				console.log('Content script -> Native app:', msg);
				if (nativePort) {
					nativePort.postMessage(msg);
				} else {
					console.warn('Cannot forward to native app - nativePort is null');
				}
			});

			port.onDisconnect.addListener(() => {
				console.log('Content script disconnected');
				if (nativePort) {
					nativePort.disconnect();
				}
			});

		} catch (e) {
			console.error('Failed to connect to native host:', e);
			port.disconnect();
		}
	}
});
