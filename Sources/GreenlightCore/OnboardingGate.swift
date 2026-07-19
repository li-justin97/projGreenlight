import Foundation

public enum OnboardingGate {
    public static func shouldShowOnboarding(appOnboardingComplete: Bool, connectionOnboardingComplete: Bool) -> Bool {
        !appOnboardingComplete || !connectionOnboardingComplete
    }
}
