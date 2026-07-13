import Foundation
import Testing
@testable import GreenlightCore

struct AgentSessionTests {
    @Test func aggregateStatusIsRedWhenBlockedSessionExists() {
        let sessions = [
            AgentSession(id: "1", tool: .claude, project: "alpha", state: .running, since: Date()),
            AgentSession(id: "2", tool: .codex, project: "beta", state: .blocked, since: Date())
        ]

        #expect(AggregateStatus.resolve(from: sessions) == .red)
    }

    @Test func aggregateStatusIsYellowWhenInputIsNeeded() {
        let sessions = [
            AgentSession(id: "1", tool: .claude, project: "alpha", state: .needsInput, since: Date())
        ]

        #expect(AggregateStatus.resolve(from: sessions) == .yellow)
    }

    @Test func aggregateStatusIsGrayWhenNoSessionsExist() {
        #expect(AggregateStatus.resolve(from: []) == .gray)
    }

    @Test func mascotPresentationChoosesLampAndExpressionForAttentionStates() {
        #expect(AggregateStatus.red.mascotPresentation == MascotPresentation(activeLamp: .red, expression: .worried, bobbing: .urgent))
        #expect(AggregateStatus.yellow.mascotPresentation == MascotPresentation(activeLamp: .yellow, expression: .flat, bobbing: .gentle))
    }

    @Test func mascotPresentationChoosesFriendlyGreenFaceForClearStates() {
        #expect(AggregateStatus.green.mascotPresentation == MascotPresentation(activeLamp: .green, expression: .happy, bobbing: .gentle))
        #expect(AggregateStatus.done.mascotPresentation == MascotPresentation(activeLamp: .green, expression: .happy, bobbing: .gentle))
        #expect(AggregateStatus.gray.mascotPresentation == MascotPresentation(activeLamp: .none, expression: .sleepy, bobbing: .still))
    }
}
