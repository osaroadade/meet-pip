import SwiftUI

@main
struct meetpipApp: App {
    // We run the input listener on @main
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    InputListener.shared.start()
                    if let window = NSApplication.shared.windows.first {
                        window.level = .floating
                        window.styleMask.insert(.fullSizeContentView)
                        window.titlebarAppearsTransparent = true
                        window.title = "Meet PIP"
                        window.isMovableByWindowBackground = true // Allow moving by dragging background
                        window.standardWindowButton(.zoomButton)?.isHidden = true
                        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                        // window.standardWindowButton(.closeButton)?.isHidden = true // Keep close button for safety
                        window.backgroundColor = .clear // For rounded corners effect if needed
                        window.isOpaque = false
                    }
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}
