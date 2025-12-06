export interface SpeakerData {
	avatarUrl: string;
	name: string;
}

export class SpeakerDetector {
	// Map of ImageURL -> History of active states (booleans)
	private speakerHistory: Map<string, boolean[]> = new Map();
	private readonly historySize = 10;
	private readonly threshold = 0.3;

	/**
	 * Scans the document for active speakers and returns their details.
	 */
	public detect(): SpeakerData[] {
		const selector = '.qg7mD.r6DyN.xm86Be.JBY0Kc.eXUaib.KXY1yb';
		const activeClass = 'BlxGDf';
		const imgSelector = 'img';

		const elems = document.querySelectorAll(selector);
		const currentFrameSpeakers = new Map<string, SpeakerData>();

		// 1. Identify active speakers in the current frame
		elems.forEach(el => {
			const img = el.querySelector(imgSelector) as HTMLImageElement;
			if (!img || !img.src) return;

			const isActive = el.classList.contains(activeClass);

			// Update history for this speaker
			this.updateHistory(img.src, isActive);

			if (this.isSmoothedActive(img.src)) {
				// Find name
				// Traverse up to find the container that holds both image and name
				// The participant container usually has data-participant-id or is a generic tile class
				const container = el.closest('.oZRSLe') || el.closest('.kvL02d') || el.closest('[data-participant-id]');
				let name = 'Unknown';

				if (container) {
					// Try common name selectors in Meet
					// The .XEazBc class usually contains the name span and a hidden tooltip.
					// We want to avoid textContent of the container because it duplicates the name.
					const nameEl = container.querySelector('.XEazBc .notranslate, .zWGUib .notranslate');
					if (nameEl && nameEl.textContent) {
						name = nameEl.textContent.trim();
					} else {
						// Fallback
						const genericNameEl = container.querySelector('.XEazBc, .zWGUib, .NnTwjc, span.notranslate');
						if (genericNameEl) {
							// Clone and remove hidden elements to avoid duplication
							const clone = genericNameEl.cloneNode(true) as HTMLElement;
							clone.querySelectorAll('[aria-hidden="true"], [role="tooltip"]').forEach(el => el.remove());
							name = clone.textContent?.trim() || 'Unknown';
						}
					}
				}

				currentFrameSpeakers.set(img.src, {
					avatarUrl: img.src,
					name: name
				});
			}
		});

		return Array.from(currentFrameSpeakers.values());
	}

	private updateHistory(id: string, isActive: boolean) {
		if (!this.speakerHistory.has(id)) {
			this.speakerHistory.set(id, []);
		}
		const history = this.speakerHistory.get(id)!;
		history.push(isActive);
		if (history.length > this.historySize) {
			history.shift();
		}
	}

	private isSmoothedActive(id: string): boolean {
		const history = this.speakerHistory.get(id);
		if (!history) return false;
		const activeCount = history.filter(Boolean).length;
		return (activeCount / history.length) >= this.threshold;
	}
}
