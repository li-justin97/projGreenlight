import Testing
@testable import GreenlightCore

struct OnboardingGateTests {
    @Test func showsOnboardingForExistingUsersWhoHaveNotCompletedConnectionSetup() {
        #expect(OnboardingGate.shouldShowOnboarding(appOnboardingComplete: true, connectionOnboardingComplete: false) == true)
    }

    @Test func hidesOnboardingOnlyAfterBothAppAndConnectionSetupAreComplete() {
        #expect(OnboardingGate.shouldShowOnboarding(appOnboardingComplete: true, connectionOnboardingComplete: true) == false)
    }

    @Test func showsOnboardingForFreshUsers() {
        #expect(OnboardingGate.shouldShowOnboarding(appOnboardingComplete: false, connectionOnboardingComplete: false) == true)
    }
}
