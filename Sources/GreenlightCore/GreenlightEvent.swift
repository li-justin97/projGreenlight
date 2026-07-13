import Foundation

public struct GreenlightEvent: Codable, Equatable, Sendable {
    public var id: String
    public var tool: AgentTool
    public var project: String
    public var state: SessionState
    public var timestamp: Date
    public var jumpTarget: String?

    public init(
        id: String,
        tool: AgentTool,
        project: String,
        state: SessionState,
        timestamp: Date,
        jumpTarget: String? = nil
    ) {
        self.id = id
        self.tool = tool
        self.project = project
        self.state = state
        self.timestamp = timestamp
        self.jumpTarget = jumpTarget
    }

    public static func decode(jsonLine: String) throws -> GreenlightEvent {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(GreenlightEvent.self, from: Data(jsonLine.utf8))
    }
}
