import Foundation
import Testing
@testable import GreenlightCore

struct AgentConnectionInstallerTests {
    @Test func sendTestEventAppendsReadableGreenlightEvent() throws {
        let fixture = try InstallerFixture()
        let result = try fixture.installer.sendTestEvent(tool: .codex, project: "project-greenlight")

        #expect(result.installed == true)

        let bridge = EventBridge(fileURL: fixture.bridgeURL)
        let events = try bridge.poll()

        #expect(events.count == 1)
        #expect(events[0].id == "greenlight-test-codex")
        #expect(events[0].tool == .codex)
        #expect(events[0].project == "project-greenlight")
        #expect(events[0].state == .needsInput)
    }

    @Test func installClaudeCreatesBackupAndAddsHookCommandsWithoutRemovingExistingSettings() throws {
        let fixture = try InstallerFixture()
        try #"{"theme":"auto","effortLevel":"low"}"#.write(to: fixture.claudeSettingsURL, atomically: true, encoding: .utf8)

        let result = try fixture.installer.installClaude()

        #expect(result.installed == true)
        #expect(result.backupURL != nil)
        #expect(FileManager.default.fileExists(atPath: result.backupURL?.path ?? "") == true)
        #expect(FileManager.default.fileExists(atPath: fixture.scriptURL(named: "greenlight-event.sh").path) == true)

        let settingsData = try Data(contentsOf: fixture.claudeSettingsURL)
        let settings = try #require(JSONSerialization.jsonObject(with: settingsData) as? [String: Any])

        #expect(settings["theme"] as? String == "auto")
        let hooks = try #require(settings["hooks"] as? [String: Any])
        #expect((hooks["SessionStart"] as? [[String: Any]])?.isEmpty == false)
        #expect((hooks["Notification"] as? [[String: Any]])?.isEmpty == false)
        #expect((hooks["Stop"] as? [[String: Any]])?.isEmpty == false)
        #expect((hooks["StopFailure"] as? [[String: Any]])?.isEmpty == false)
    }

    @Test func installCodexCreatesWrapperAndPreservesExistingNotifyCommand() throws {
        let fixture = try InstallerFixture()
        try """
        model = "gpt-5.5"
        notify = ["/Applications/Old Notifier.app/Contents/MacOS/notifier", "turn-ended"]
        """.write(to: fixture.codexConfigURL, atomically: true, encoding: .utf8)

        let result = try fixture.installer.installCodex()

        #expect(result.installed == true)
        #expect(result.backupURL != nil)
        #expect(FileManager.default.fileExists(atPath: result.backupURL?.path ?? "") == true)

        let config = try String(contentsOf: fixture.codexConfigURL, encoding: .utf8)
        #expect(config.contains("notify = [\"\(fixture.scriptURL(named: "greenlight-codex-notify.sh").path)\""))
        #expect(config.contains("model = \"gpt-5.5\""))

        let wrapper = try String(contentsOf: fixture.scriptURL(named: "greenlight-codex-notify.sh"), encoding: .utf8)
        #expect(wrapper.contains("/Applications/Old Notifier.app/Contents/MacOS/notifier"))
        #expect(wrapper.contains("turn-ended"))
        #expect(wrapper.contains("greenlight-event.sh"))
    }

    @Test func statusReflectsInstalledConnections() throws {
        let fixture = try InstallerFixture()
        var status = fixture.installer.status()
        #expect(status.claudeInstalled == false)
        #expect(status.codexInstalled == false)

        _ = try fixture.installer.installClaude()
        _ = try fixture.installer.installCodex()

        status = fixture.installer.status()
        #expect(status.claudeInstalled == true)
        #expect(status.codexInstalled == true)
    }
}

private struct InstallerFixture {
    let root: URL
    let appSupportURL: URL
    let claudeSettingsURL: URL
    let codexConfigURL: URL
    let bridgeURL: URL
    let installer: AgentConnectionInstaller

    init() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        appSupportURL = root.appendingPathComponent("Application Support/Greenlight", isDirectory: true)
        claudeSettingsURL = root.appendingPathComponent(".claude/settings.json")
        codexConfigURL = root.appendingPathComponent(".codex/config.toml")
        bridgeURL = appSupportURL.appendingPathComponent("events.jsonl")

        try FileManager.default.createDirectory(at: claudeSettingsURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: codexConfigURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)

        installer = AgentConnectionInstaller(
            appSupportURL: appSupportURL,
            bridgeURL: bridgeURL,
            claudeSettingsURL: claudeSettingsURL,
            codexConfigURL: codexConfigURL,
            now: { Date(timeIntervalSince1970: 1_789_423_200) }
        )
    }

    func scriptURL(named name: String) -> URL {
        appSupportURL.appendingPathComponent(name)
    }
}
