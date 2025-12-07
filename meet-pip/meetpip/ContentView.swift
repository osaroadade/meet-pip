import SwiftUI

struct ContentView: View {
    @ObservedObject var listener = InputListener.shared
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Mute Control (Always visible, on the left)
             Button(action: {
                 listener.sendMuteToggle()
                 // Optimistic update
                //  listener.isMuted.toggle() // We wait for server source of truth now
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
            
            // Speakers
            ForEach(listener.speakers, id: \.self) { speaker in
                VStack(spacing: 2) {
                    AsyncImage(url: URL(string: speaker.avatarUrl)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 48, height: 48) // Reverted to 48
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.green, lineWidth: 2))
                                .shadow(radius: 3)
                        } else if phase.error != nil {
                            Circle().fill(Color.red).frame(width: 48, height: 48)
                        } else {
                            Circle().fill(Color.gray).frame(width: 48, height: 48)
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
                        .frame(maxWidth: 80)
                }
            }
        }
        .padding(8) // Padding around the whole strip
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
        .onChange(of: listener.speakers) { newSpeakers in
            resizeWindow(count: newSpeakers.count)
        }
        .onAppear {
            resizeWindow(count: listener.speakers.count)
        }
    }
    
    private func resizeWindow(count: Int) {
        DispatchQueue.main.async {
            guard let window = NSApplication.shared.windows.first else { return }
            
            // Horizontal layout calculation
            // Mute button (32) + Spacing (8) + (Count * (Avatar/Name width (~80) + Spacing(8)))
            let muteWidth: CGFloat = 32 + 8
            let itemWidth: CGFloat = 80 + 8
            let contentWidth = muteWidth + (CGFloat(count) * itemWidth) + 16 // + padding
            
            let contentHeight: CGFloat = 90 // Avatar(48) + Name(20) + Spacing + Padding
            
            var frame = window.frame
            let oldY = frame.origin.y + frame.height // Top-left anchor logic
            let newY = oldY - contentHeight
            
            window.setFrame(NSRect(x: frame.origin.x, y: newY, width: contentWidth, height: contentHeight), display: true, animate: true)
        }
    }
}

