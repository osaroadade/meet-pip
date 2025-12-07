import SwiftUI

@main
struct meetpipApp: App {
    init() {
        // Start listening immediately when app launches, regardless of UI state
        InputListener.shared.start()
    }
    
    // We run the input listener on @main
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    if let window = NSApplication.shared.windows.first {
                        window.level = .floating
                        // Borderless
                        window.styleMask = [.borderless] 
                        window.backgroundColor = .clear 
                        window.isOpaque = false
                        window.hasShadow = false
                        window.isMovableByWindowBackground = true 
                    }
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}
