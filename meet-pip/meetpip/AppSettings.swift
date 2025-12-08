import SwiftUI

enum LayoutOrientation: String, CaseIterable {
    case horizontal = "Horizontal"
    case vertical = "Vertical"
}

struct AppSettings {
    // Keys for UserDefaults
    static let layoutOrientationKey = "layoutOrientation"
    static let avatarSizeKey = "avatarSize"
    
    // Validation constants
    static let minAvatarSize: Double = 28.0
    static let maxAvatarSize: Double = 128.0
    static let defaultAvatarSize: Double = 48.0
}
