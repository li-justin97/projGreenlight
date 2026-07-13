import Combine
import Foundation

public final class SessionStore: ObservableObject {
    @Published public private(set) var sessions: [AgentSession]

    public init(sessions: [AgentSession] = []) {
        self.sessions = sessions
    }

    public var aggregateStatus: AggregateStatus {
        AggregateStatus.resolve(from: sessions)
    }

    public func apply(event: GreenlightEvent) {
        let session = AgentSession(
            id: event.id,
            tool: event.tool,
            project: event.project,
            state: event.state,
            since: event.timestamp,
            escalated: false,
            jumpTarget: event.jumpTarget
        )

        if let index = sessions.firstIndex(where: { $0.id == event.id }) {
            sessions[index] = session
        } else {
            sessions.append(session)
        }
    }

    public func refreshEscalation(now: Date = Date(), escalationDelay: TimeInterval) {
        sessions = sessions.map { session in
            guard session.state == .needsInput else {
                return session
            }

            var updated = session
            updated.escalated = now.timeIntervalSince(session.since) > escalationDelay
            return updated
        }
    }

    public func seedDemoSessions(now: Date = Date()) {
        sessions = [
            AgentSession(id: "demo-claude", tool: .claude, project: "project-greenlight", state: .needsInput, since: now.addingTimeInterval(-192)),
            AgentSession(id: "demo-codex", tool: .codex, project: "api-refactor", state: .running, since: now.addingTimeInterval(-258)),
            AgentSession(id: "demo-done", tool: .claude, project: "marketing-site", state: .done, since: now.addingTimeInterval(-41)),
            AgentSession(id: "demo-infra", tool: .codex, project: "infra-scripts", state: .running, since: now.addingTimeInterval(-1_332))
        ]
    }

    public func clearDemoSessions() {
        sessions.removeAll()
    }
}
