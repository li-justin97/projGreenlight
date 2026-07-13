import Foundation

public final class EventBridge {
    public let fileURL: URL
    private var readOffset: UInt64

    public init(fileURL: URL = EventBridge.defaultFileURL()) {
        self.fileURL = fileURL
        self.readOffset = 0
    }

    public static func defaultFileURL() -> URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        return support
            .appendingPathComponent("Greenlight", isDirectory: true)
            .appendingPathComponent("events.jsonl")
    }

    public func ensureFileExists() throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        }
    }

    public func poll() throws -> [GreenlightEvent] {
        try ensureFileExists()
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { try? handle.close() }

        let fileSize = try handle.seekToEnd()
        if readOffset > fileSize {
            readOffset = 0
        }

        try handle.seek(toOffset: readOffset)
        let data = try handle.readToEnd() ?? Data()
        readOffset = fileSize

        guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else {
            return []
        }

        return text
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { line in
                try? GreenlightEvent.decode(jsonLine: String(line))
            }
    }
}
