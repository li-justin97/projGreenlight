import Foundation
import Testing
@testable import GreenlightCore

struct SessionStoreTests {
    @Test func applyEventCreatesSession() {
        let store = SessionStore()
        let timestamp = Date(timeIntervalSince1970: 100)
        let event = GreenlightEvent(
            id: "project-greenlight",
            tool: .claude,
            project: "project-greenlight",
            state: .needsInput,
            timestamp: timestamp,
            jumpTarget: "/tmp/project-greenlight"
        )

        store.apply(event: event)

        #expect(store.sessions == [
            AgentSession(
                id: "project-greenlight",
                tool: .claude,
                project: "project-greenlight",
                state: .needsInput,
                since: timestamp,
                jumpTarget: "/tmp/project-greenlight"
            )
        ])
    }

    @Test func applyEventUpdatesExistingSessionAndClearsEscalation() {
        let store = SessionStore()
        let first = Date(timeIntervalSince1970: 100)
        let second = Date(timeIntervalSince1970: 200)

        store.apply(event: GreenlightEvent(id: "same", tool: .codex, project: "old", state: .needsInput, timestamp: first, jumpTarget: nil))
        store.refreshEscalation(now: first.addingTimeInterval(700), escalationDelay: 600)
        store.apply(event: GreenlightEvent(id: "same", tool: .codex, project: "new", state: .running, timestamp: second, jumpTarget: "/tmp/new"))

        #expect(store.sessions.count == 1)
        #expect(store.sessions[0].project == "new")
        #expect(store.sessions[0].state == .running)
        #expect(store.sessions[0].since == second)
        #expect(store.sessions[0].escalated == false)
        #expect(store.sessions[0].jumpTarget == "/tmp/new")
    }

    @Test func refreshEscalationMarksLongWaitingInputSession() {
        let store = SessionStore()
        let timestamp = Date(timeIntervalSince1970: 100)
        store.apply(event: GreenlightEvent(id: "waiting", tool: .claude, project: "waiting", state: .needsInput, timestamp: timestamp, jumpTarget: nil))

        store.refreshEscalation(now: timestamp.addingTimeInterval(601), escalationDelay: 600)

        #expect(store.sessions[0].escalated == true)
        #expect(AggregateStatus.resolve(from: store.sessions) == .red)
    }
}
