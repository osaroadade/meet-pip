import SwiftUI

struct SettingsView: View {
    @AppStorage(AppSettings.layoutOrientationKey) private var layoutOrientation = LayoutOrientation.horizontal.rawValue
    @AppStorage(AppSettings.avatarSizeKey) private var avatarSize = AppSettings.defaultAvatarSize
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Meet PIP Settings")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.bottom, 8)
                
                // Layout Orientation
                VStack(alignment: .leading, spacing: 8) {
                    Text("Layout Orientation")
                        .font(.headline)
                    
                    Picker("Layout", selection: $layoutOrientation) {
                        ForEach(LayoutOrientation.allCases, id: \.self) { orientation in
                            Text(orientation.rawValue).tag(orientation.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Text("Choose how speakers are arranged in the PIP window")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Avatar Size
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Profile Picture Size")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(avatarSize))px")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: $avatarSize,
                        in: AppSettings.minAvatarSize...AppSettings.maxAvatarSize,
                        step: 4
                    )
                    
                    HStack {
                        Text("\(Int(AppSettings.minAvatarSize))px")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(AppSettings.maxAvatarSize))px")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Preview circle
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: CGFloat(avatarSize), height: CGFloat(avatarSize))
                            .overlay(
                                Circle()
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                            .overlay(
                                Text("Preview")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            )
                        Spacer()
                    }
                    .padding(.top, 8)
                    
                    Text("Adjust the size of profile pictures in the PIP window")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer(minLength: 20)
                
                // Reset to defaults button
                HStack {
                    Spacer()
                    Button("Reset to Defaults") {
                        layoutOrientation = LayoutOrientation.horizontal.rawValue
                        avatarSize = AppSettings.defaultAvatarSize
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(24)
        }
        .frame(width: 450)
        .frame(minHeight: 400, maxHeight: 600)
    }
}

// Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
