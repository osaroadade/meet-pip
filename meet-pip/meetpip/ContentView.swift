import SwiftUI

struct ContentView: View {
    @ObservedObject var listener = InputListener.shared
    @AppStorage(AppSettings.layoutOrientationKey) private var layoutOrientation = LayoutOrientation.horizontal.rawValue
    @AppStorage(AppSettings.avatarSizeKey) private var avatarSize = AppSettings.defaultAvatarSize
    @State private var isHovering = false
    
    private var orientation: LayoutOrientation {
        LayoutOrientation(rawValue: layoutOrientation) ?? .horizontal
    }
    
    private var avatarSizeCGFloat: CGFloat {
        CGFloat(avatarSize)
    }
    
    var body: some View {
        Group {
            if orientation == .horizontal {
                horizontalLayout
            } else {
                verticalLayout
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.001)) // Interactive background for dragging
        .gesture(
            DragGesture()
                .onChanged { _ in
                     if let window = NSApplication.shared.windows.first, let event = NSApp.currentEvent {
                         window.performDrag(with: event)
                     }
                }
        )
        .background(Color.clear)
        .onHover { hover in
            isHovering = hover
        }
        .onChange(of: avatarSize) { _ in
            resizeWindow()
        }
        .onChange(of: layoutOrientation) { _ in
            resizeWindow()
        }
        .onAppear {
            resizeWindow()
        }
    }
    
    // Horizontal Layout (Left to Right)
    private var horizontalLayout: some View {
        HStack(spacing: 8) {
            muteButton
            
            ForEach(listener.speakers, id: \.self) { speaker in
                speakerView(speaker)
            }
        }
    }
    
    // Vertical Layout (Top to Bottom)
    private var verticalLayout: some View {
        VStack(spacing: 8) {
            muteButton
            
            ForEach(listener.speakers, id: \.self) { speaker in
                speakerView(speaker)
            }
        }
    }
    
    // Mute Button Component
    private var muteButton: some View {
        Button(action: {
            listener.sendMuteToggle()
        }) {
            Image(systemName: listener.isMuted ? "mic.slash.fill" : "mic.fill")
                .font(.system(size: 14))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(listener.isMuted ? Color.red.opacity(0.8) : Color.gray.opacity(0.6))
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .shadow(radius: 2)
        .keyboardShortcut("m", modifiers: [.command, .shift])
    }
    
    // Speaker View Component
    private func speakerView(_ speaker: Speaker) -> some View {
        VStack(spacing: 2) {
            AsyncImage(url: URL(string: speaker.avatarUrl)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: avatarSizeCGFloat, height: avatarSizeCGFloat)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.green, lineWidth: 2))
                        .shadow(radius: 3)
                } else if phase.error != nil {
                    Circle().fill(Color.red).frame(width: avatarSizeCGFloat, height: avatarSizeCGFloat)
                } else {
                    Circle().fill(Color.gray).frame(width: avatarSizeCGFloat, height: avatarSizeCGFloat)
                }
            }
            
            Text(speaker.name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.6))
                .cornerRadius(4)
                .lineLimit(1)
                .frame(maxWidth: max(80, avatarSizeCGFloat))
        }
    }
    
    private func resizeWindow() {
        DispatchQueue.main.async {
            guard let window = NSApplication.shared.windows.first else { return }
            
            let avatarSize = avatarSizeCGFloat
            let muteButtonSize: CGFloat = 32
            let spacing: CGFloat = 8
            let padding: CGFloat = 16
            let nameHeight: CGFloat = 20
            
            // Calculate dimensions for consistent window size
            let contentWidth: CGFloat
            let contentHeight: CGFloat
            
            if orientation == .horizontal {
                // Horizontal: Fixed height, always accommodate at least the mute button + avatar
                let itemWidth = max(80, avatarSize)
                // Keep width to fit mute button + spacing, ready for speakers
                contentWidth = muteButtonSize + spacing + itemWidth + padding
                // Height stays consistent based on avatar size
                contentHeight = avatarSize + nameHeight + spacing + padding
            } else {
                // Vertical: Fixed width, height based on avatar size
                let itemWidth = max(80, avatarSize)
                contentWidth = itemWidth + padding
                // Keep enough height for mute button + one speaker item minimum
                contentHeight = muteButtonSize + spacing + avatarSize + nameHeight + spacing * 2 + padding
            }
            
            var frame = window.frame
            let oldY = frame.origin.y + frame.height // Top-left anchor logic
            let newY = oldY - contentHeight
            
            window.setFrame(NSRect(x: frame.origin.x, y: newY, width: contentWidth, height: contentHeight), display: true, animate: true)
        }
    }
}