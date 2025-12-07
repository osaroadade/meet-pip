// Block Picture-in-Picture completely
// Runs at document_start before Google Meet's JavaScript loads

(function () {
	console.log('[MeetPIP] Installing PIP blocker...');

	// Block Video PIP (legacy API, rarely used by Meet)
	if (HTMLVideoElement.prototype.requestPictureInPicture) {
		HTMLVideoElement.prototype.requestPictureInPicture = function () {
			console.log('[MeetPIP] Blocked video PIP request');
			return Promise.reject(new DOMException('Picture-in-Picture disabled by MeetPIP extension', 'NotAllowedError'));
		};
	}

	// Allow PIP feature detection so Meet renders videos normally
	// (Returning false causes Meet to disable video rendering)
	Object.defineProperty(document, 'pictureInPictureEnabled', {
		get: function () {
			return true;
		},
		configurable: false
	});

	// Monitor for unexpected PIP activation
	const originalPIPElement = Object.getOwnPropertyDescriptor(Document.prototype, 'pictureInPictureElement');
	if (originalPIPElement) {
		Object.defineProperty(document, 'pictureInPictureElement', {
			get: function () {
				const element = originalPIPElement.get.call(this);
				if (element) {
					console.warn('[MeetPIP] Unexpected PIP element detected:', element);
				}
				return element;
			},
			configurable: false
		});
	}

	// Block exitPictureInPicture
	if (document.exitPictureInPicture) {
		document.exitPictureInPicture = function () {
			return Promise.resolve();
		};
	}

	// Block Document PIP API (what Meet actually uses)
	if (window.documentPictureInPicture) {
		Object.defineProperty(window, 'documentPictureInPicture', {
			value: {
				requestWindow: function () {
					console.log('[MeetPIP] Blocked Document PIP request');
					return Promise.reject(new DOMException('Document Picture-in-Picture disabled by MeetPIP extension', 'NotAllowedError'));
				},
				get window() {
					return null;
				}
			},
			writable: false,
			configurable: false
		});
	}

	console.log('[MeetPIP] PIP blocker installed successfully');
})();
