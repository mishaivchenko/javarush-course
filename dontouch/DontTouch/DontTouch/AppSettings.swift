import Foundation
import Combine

/// Shared settings manager using App Groups for communication between
/// the macOS host app and the Safari extension.
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let defaults: UserDefaults

    static let appGroupIdentifier = "group.com.yourname.donttouch"

    @Published var sensitivityThreshold: Double {
        didSet { defaults.set(sensitivityThreshold, forKey: "sensitivityThreshold") }
    }

    @Published var extensionEnabled: Bool {
        didSet { defaults.set(extensionEnabled, forKey: "extensionEnabled") }
    }

    private init() {
        // Use App Groups so the Safari extension can read these values
        self.defaults = UserDefaults(suiteName: Self.appGroupIdentifier)
            ?? UserDefaults.standard

        self.sensitivityThreshold = defaults.object(forKey: "sensitivityThreshold") as? Double ?? 0.6
        self.extensionEnabled = defaults.object(forKey: "extensionEnabled") as? Bool ?? false
    }

    /// Reset all settings to defaults.
    func reset() {
        sensitivityThreshold = 0.6
        extensionEnabled = false
    }

    /// Register App Group defaults for extension access.
    static func registerDefaults() {
        UserDefaults(suiteName: appGroupIdentifier)?
            .register(defaults: [
                "sensitivityThreshold": 0.6,
                "extensionEnabled": false
            ])
    }
}
