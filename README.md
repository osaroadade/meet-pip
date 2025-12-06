# Meet PIP

Meet PIP is a hybrid application that enhances the Google Meet Picture-in-Picture experience by calculating the active speaker and rendering them in a native macOS window. This project combines a Chrome Extension with a native Swift application.

## Project Structure

- **`src/`**: Source code for the Chrome Extension (Content Script, Background Script).
- **`meetpip/`**: Source code for the native macOS application (Swift/SwiftUI).
- **`native-setup/`**: Scripts and configuration for setting up the Native Messaging Host.

## Prerequisites

- Node.js (v18+ recommended)
- Xcode (for building the native app)
- Google Chrome

## Installation & Setup

1.  **Install Dependencies**
    ```bash
    npm install
    ```

2.  **Build the Extension**
    ```bash
    npm run build
    ```
    This will generate the extension assets in the `dist/` directory.

3.  **Load Extension in Chrome**
    - Open Chrome and navigate to `chrome://extensions/`.
    - Enable "Developer mode".
    - Click "Load unpacked" and select the `dist` directory.

4.  **Setup Native Messaging Host**
    Run the installation script to register the native host manifest:
    ```bash
    cd native-setup
    ./install.sh
    ```

5.  **Build Native App**
    - Open `meetpip/MeetPIP.xcodeproj` in Xcode.
    - Build and Run the application.

## Development

To start the Vite development server for the UI components:

```bash
npm run dev
```

## Scripts

- `npm run dev`: Start the dev server.
- `npm run build`: Type-check and build all parts of the extension (Main, Content, Background).
- `npm run preview`: Preview the build.
