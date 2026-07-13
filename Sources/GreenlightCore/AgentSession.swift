import Foundation

public enum AgentTool: String, Codable, Equatable, Sendable {
    case claude
    case codex
    case other

    public var displayName: String {
        switch self {
        case .claude: "Claude Code"
        case .codex: "Codex"
        case .other: "Agent"
        }
    }

    public var tag: String {
        switch self {
        case .claude: "CC"
        case .codex: "CX"
        case .other: "--"
        }
    }
}

public enum SessionState: String, Codable, Equatable, Sendable {
    case running
    case needsInput
    case blocked
    case done
    case idle
}

public struct AgentSession: Identifiable, Equatable, Sendable {
    public var id: String
    public var tool: AgentTool
    public var project: String
    public var state: SessionState
    public var since: Date
    public var escalated: Bool
    public var jumpTarget: String?

    public init(
        id: String,
        tool: AgentTool,
        project: String,
        state: SessionState,
        since: Date,
        escalated: Bool = false,
        jumpTarget: String? = nil
    ) {
        self.id = id
        self.tool = tool
        self.project = project
        self.state = state
        self.since = since
        self.escalated = escalated
        self.jumpTarget = jumpTarget
    }
}

public enum AggregateStatus: Equatable, Sendable {
    case red
    case yellow
    case green
    case done
    case gray

    public static func resolve(from sessions: [AgentSession]) -> AggregateStatus {
        if sessions.isEmpty {
            return .gray
        }

        if sessions.contains(where: { $0.state == .blocked || ($0.state == .needsInput && $0.escalated) }) {
            return .red
        }

        if sessions.contains(where: { $0.state == .needsInput }) {
            return .yellow
        }

        if sessions.contains(where: { $0.state == .running }) {
            return .green
        }

        if sessions.contains(where: { $0.state == .done }) {
            return .done
        }

        return .gray
    }

    public var mascotPresentation: MascotPresentation {
        switch self {
        case .red:
            return MascotPresentation(activeLamp: .red, expression: .worried, bobbing: .urgent)
        case .yellow:
            return MascotPresentation(activeLamp: .yellow, expression: .flat, bobbing: .gentle)
        case .green, .done:
            return MascotPresentation(activeLamp: .green, expression: .happy, bobbing: .gentle)
        case .gray:
            return MascotPresentation(activeLamp: .none, expression: .sleepy, bobbing: .still)
        }
    }
}

public struct MascotPresentation: Equatable, Sendable {
    public var activeLamp: MascotLamp
    public var expression: MascotExpression
    public var bobbing: MascotBobbing

    public init(activeLamp: MascotLamp, expression: MascotExpression, bobbing: MascotBobbing) {
        self.activeLamp = activeLamp
        self.expression = expression
        self.bobbing = bobbing
    }
}

public enum MascotLamp: Equatable, Sendable {
    case red
    case yellow
    case green
    case none
}

public enum MascotExpression: Equatable, Sendable {
    case happy
    case flat
    case worried
    case sleepy
}

public enum MascotBobbing: Equatable, Sendable {
    case gentle
    case urgent
    case still
}
