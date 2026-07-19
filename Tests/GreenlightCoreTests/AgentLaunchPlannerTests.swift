import Foundation
import Testing
@testable import GreenlightCore

struct AgentLaunchPlannerTests {
    @Test func claudeSessionLaunchesClaudeCodeFromJumpTargetDirectory() {
        let session = AgentSession(
            id: "claude:/tmp/project",
            tool: .claude,
            project: "project",
            state: .needsInput,
            since: Date(timeIntervalSince1970: 0),
            jumpTarget: "/tmp/project"
        )

        let plan = AgentLaunchPlanner.plan(for: session)

        #expect(plan == .terminal(command: "cd '/tmp/project' && claude --continue"))
    }

    @Test func codexSessionLaunchesCodexApp() {
        let session = AgentSession(
            id: "codex:/tmp/project",
            tool: .codex,
            project: "project",
            state: .needsInput,
            since: Date(timeIntervalSince1970: 0),
            jumpTarget: "/tmp/project"
        )

        let plan = AgentLaunchPlanner.plan(for: session)

        #expect(plan == .application(path: "/Applications/Codex.app"))
    }

    @Test func otherSessionFallsBackToOpeningJumpTarget() {
        let session = AgentSession(
            id: "other:/tmp/project",
            tool: .other,
            project: "project",
            state: .needsInput,
            since: Date(timeIntervalSince1970: 0),
            jumpTarget: "/tmp/project"
        )

        let plan = AgentLaunchPlanner.plan(for: session)

        #expect(plan == .file(path: "/tmp/project"))
    }
}
