import SwiftUI

struct ContentView: View {
    @ObservedObject var listener = InputListener.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            if !listener.speakers.isEmpty {
                 Text("\(listener.speakers.count) Active Speaker(s)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.leading, 10)
                    .padding(.top, 10)
                    .shadow(radius: 2)
            } else {
                 Text("Waiting for speakers...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(10)
            }
            
            // Speaker List
            ForEach(listener.speakers, id: \.self) { speaker in
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: speaker.avatarUrl)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.green, lineWidth: 2))
                                .shadow(radius: 4)
                        } else if phase.error != nil {
                            Circle().fill(Color.red).frame(width: 50, height: 50)
                        } else {
                            Circle().fill(Color.gray).frame(width: 50, height: 50)
                        }
                    }
                    
                    Text(speaker.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(6)
                        .lineLimit(1)
                        .shadow(radius: 2)
                    
                    Spacer()
                }
                .padding(.horizontal, 10)
            }
        }
        .background(Color.clear) // Transparent background
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
            
            // Calculate height
            // Header (~30) + (Count * Row(~60)) + Padding
            let itemHeight: CGFloat = 62 // 50 image + spacing
            let headerHeight: CGFloat = 30
            let baseHeight: CGFloat = count == 0 ? 50 : headerHeight
            let contentHeight = baseHeight + (CGFloat(count) * itemHeight) + 10
            
            let width: CGFloat = 250
            
            var frame = window.frame
            let oldHeight = frame.height
            // Anchor top-left corner
            let newY = frame.origin.y + (oldHeight - contentHeight)
            
            window.setFrame(NSRect(x: frame.origin.x, y: newY, width: width, height: contentHeight), display: true, animate: true)
        }
    }
}

