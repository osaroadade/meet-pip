import './style.css';
import { SpeakerData, SpeakerDetector } from './detector';

const app = document.querySelector<HTMLDivElement>('#app')!;

app.innerHTML = `
  <div>
    <h1>Measure PIP for Google Meet</h1>
    
    <div id="pip-status" class="inactive">
      No Speaker Detected
    </div>

    <div id="speaker-list"></div>

    <div id="controls">
      <p>Loading HTML dump...</p>
    </div>

    <!-- Hidden container for the dump -->
    <div id="dump-container"></div>
  </div>
`;

const statusEl = document.getElementById('pip-status')!;
const speakerListEl = document.getElementById('speaker-list')!;
const dumpContainer = document.getElementById('dump-container')!;
const detector = new SpeakerDetector();

// Function to fetch and inject the dump
async function loadDump() {
	try {
		const response = await fetch('/html-dump/2-peakers.html');
		if (!response.ok) throw new Error('Failed to load dump');
		const html = await response.text();
		dumpContainer.innerHTML = html;
		console.log('Dump loaded successfully');
	} catch (e) {
		console.error(e);
		dumpContainer.innerHTML = '<p style="color:red">Failed to load HTML dump. Make sure /html-dump/2-peakers.html exists and is serveable.</p>';
	}
}

// Detection loop
function startDetection() {
	const loop = () => {
		const speakers = detector.detect();

		if (speakers.length > 0) {
			statusEl.textContent = `${speakers.length} Active Speaker(s)`;
			statusEl.className = 'active';
		} else {
			statusEl.textContent = 'No Speaker Detected';
			statusEl.className = 'inactive';
		}

		renderSpeakerBubbles(speakers);

		requestAnimationFrame(loop);
	};
	requestAnimationFrame(loop);
}

function renderSpeakerBubbles(speakers: SpeakerData[]) {
	// Clearing and re-rendering for simplicity in V1
	speakerListEl.innerHTML = '';
	speakers.forEach(speaker => {
		const container = document.createElement('div');
		container.className = 'speaker-item';
		container.style.display = 'inline-block';
		container.style.margin = '10px';
		container.style.textAlign = 'center';

		const img = document.createElement('img');
		img.src = speaker.avatarUrl;
		img.className = 'bubble';
		img.style.display = 'block';
		img.style.marginBottom = '5px';

		const name = document.createElement('div');
		name.textContent = speaker.name;
		name.style.fontSize = '12px';
		name.style.fontWeight = 'bold';

		container.appendChild(img);
		container.appendChild(name);
		speakerListEl.appendChild(container);
	});
}

// Initialize
loadDump().then(() => {
	startDetection();
});
