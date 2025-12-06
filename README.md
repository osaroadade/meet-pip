# Meet PIP

Meet PIP is a hybrid application that enhances the Google Meet Picture-in-Picture experience by calculating the active speaker and rendering them in a native macOS window. This project combines a Chrome Extension with a native Swift application.

## Project Structure

- **`src/`**: Source code for the Chrome Extension (Content Script, Background Script).
- **`meet-pip/`**: Source code for the native macOS application (Swift/SwiftUI).
- **`native-setup/`**: Scripts and configuration for setting up the Native Messaging Host.

## Prerequisites

- Node.js (v18+ recommended)
- Xcode (latest version) & Xcode Command Line Tools
- Google Chrome

## Installation & Setup

We use a `Makefile` to streamline the build and setup process.

### 1. Install Dependencies & Build
Install Node dependencies and build both the extension and the native app:

```bash
make install
make build
```

This will:
- Build the Chrome Extension into `dist/`.
- Build the Native App into `meet-pip/DerivedData/`.

### 2. Load Extension in Chrome
1.  Open Chrome and navigate to `chrome://extensions/`.
2.  Enable "Developer mode" (top right).
3.  Click "Load unpacked" and select the `dist` directory in this project.
4.  copy the **ID** of the newly loaded extension (e.g., `gpdhpobcgfffikfchpgdffmbbkllgmfm`).

### 3. Configure Native Host
1.  Copy the example configuration file:
    ```bash
    cp .env.example .env
    ```
2.  Open `.env` and paste your Extension ID:
    ```env
    EXTENSION_ID=your_copied_id_here
    ```
3.  Run the setup script:
    ```bash
    make setup
    ```

This script will register the native messaging host with Chrome, pointing it to your local build of the native app.

### 4. Verify
1.  Open a Google Meet session.
2.  You should see a "Start Native PIP" button.
3.  Clicking it should launch the native MeetPIP window.

## Development

- `make build-extension`: Rebuild just the extension.
- `make build-app`: Rebuild just the native app.
- `npm run dev`: Start the Vite dev server for UI components.

## Troubleshooting

**"Native PiP blocked" not appearing?**
Reload the extension in `chrome://extensions` and refresh the Google Meet page.

**"Translation context invalidated"?**
The extension supports hot-reloading. Just reload the extension in `chrome://extensions` and the "Start Native PIP" button should refresh automatically.

**"Binary not found"?**
Run `make build-app` to ensure the native application is compiled.

## License

ISC
