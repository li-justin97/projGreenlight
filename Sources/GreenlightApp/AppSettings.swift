import Combine
import Foundation

@MainActor
final class AppSettings: ObservableObject {
    @Published var showCount: Bool {
        didSet { defaults.set(showCount, forKey: Keys.showCount) }
    }

    @Published var playfulMascot: Bool {
        didSet { defaults.set(playfulMascot, forKey: Keys.playfulMascot) }
    }

    @Published var escalationDelay: TimeInterval {
        didSet { defaults.set(escalationDelay, forKey: Keys.escalationDelay) }
    }

    @Published var demoMode: Bool {
        didSet { defaults.set(demoMode, forKey: Keys.demoMode) }
    }

    @Published var onboardingComplete: Bool {
        didSet { defaults.set(onboardingComplete, forKey: Keys.onboardingComplete) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.showCount = defaults.object(forKey: Keys.showCount) as? Bool ?? true
        self.playfulMascot = defaults.object(forKey: Keys.playfulMascot) as? Bool ?? true
        self.escalationDelay = defaults.object(forKey: Keys.escalationDelay) as? TimeInterval ?? 600
        self.demoMode = defaults.object(forKey: Keys.demoMode) as? Bool ?? true
        self.onboardingComplete = defaults.object(forKey: Keys.onboardingComplete) as? Bool ?? false
    }

    private enum Keys {
        static let showCount = "showCount"
        static let playfulMascot = "playfulMascot"
        static let escalationDelay = "escalationDelay"
        static let demoMode = "demoMode"
        static let onboardingComplete = "onboardingComplete"
    }
}
