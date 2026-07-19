import Foundation

public enum AgentLaunchPlan: Equatable, Sendable {
    case application(path: String)
    case terminal(command: String)
    case file(path: String)
    case none
}

public enum AgentLaunchPlanner {
    public static func plan(for session: AgentSession) -> AgentLaunchPlan {
        switch session.tool {
        case .claude:
            guard let directory = launchDirectory(for: session) else {
                return .terminal(command: "claude --continue")
            }
            return .terminal(command: "cd \(shellQuote(directory)) && claude --continue")
        case .codex:
            return .application(path: "/Applications/Codex.app")
        case .other:
            guard let directory = launchDirectory(for: session) else {
                return .none
            }
            return .file(path: directory)
        }
    }

    private static func launchDirectory(for session: AgentSession) -> String? {
        guard let jumpTarget = session.jumpTarget, !jumpTarget.isEmpty else {
            return nil
        }
        return jumpTarget
    }

    private static func shellQuote(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}
