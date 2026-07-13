import Foundation
import Testing
@testable import GreenlightCore

struct EventBridgeTests {
    @Test func decodesValidJSONLine() throws {
        let line = #"{"id":"manual","tool":"claude","project":"manual-test","state":"needsInput","timestamp":"2026-07-13T13:41:00Z","jumpTarget":"/tmp/manual"}"#

        let event = try GreenlightEvent.decode(jsonLine: line)

        #expect(event.id == "manual")
        #expect(event.tool == .claude)
        #expect(event.project == "manual-test")
        #expect(event.state == .needsInput)
        #expect(event.jumpTarget == "/tmp/manual")
    }

    @Test func bridgeIgnoresInvalidLines() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jsonl")
        try #"{"id":"valid","tool":"codex","project":"api","state":"running","timestamp":"2026-07-13T13:41:00Z"}"#
            .appending("\nnot-json\n")
            .write(to: url, atomically: true, encoding: .utf8)

        let bridge = EventBridge(fileURL: url)

        let events = try bridge.poll()

        #expect(events.map(\.id) == ["valid"])
    }

    @Test func bridgeReadsOnlyAppendedLinesAfterFirstPoll() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jsonl")
        let first = #"{"id":"first","tool":"codex","project":"api","state":"running","timestamp":"2026-07-13T13:41:00Z"}"#
        let second = #"{"id":"second","tool":"claude","project":"ui","state":"done","timestamp":"2026-07-13T13:42:00Z"}"#
        try "\(first)\n".write(to: url, atomically: true, encoding: .utf8)
        let bridge = EventBridge(fileURL: url)

        let firstPoll = try bridge.poll()
        try FileHandle(forWritingTo: url).writeToEnd("\(second)\n")
        let secondPoll = try bridge.poll()

        #expect(firstPoll.map(\.id) == ["first"])
        #expect(secondPoll.map(\.id) == ["second"])
    }
}

private extension FileHandle {
    func writeToEnd(_ string: String) throws {
        defer { try? close() }
        seekToEndOfFile()
        try write(contentsOf: Data(string.utf8))
    }
}
