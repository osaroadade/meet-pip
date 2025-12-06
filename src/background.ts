const HOST_NAME = 'com.meetpip.app';

console.log('Background script loaded');

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
				if (nativePort) {
					nativePort.postMessage(msg);
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
