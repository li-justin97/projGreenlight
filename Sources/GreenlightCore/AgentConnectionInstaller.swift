import Foundation

public struct ConnectionInstallResult: Equatable, Sendable {
    public var installed: Bool
    public var message: String
    public var backupURL: URL?

    public init(installed: Bool, message: String, backupURL: URL? = nil) {
        self.installed = installed
        self.message = message
        self.backupURL = backupURL
    }
}

public struct AgentConnectionStatus: Equatable, Sendable {
    public var claudeInstalled: Bool
    public var codexInstalled: Bool

    public init(claudeInstalled: Bool, codexInstalled: Bool) {
        self.claudeInstalled = claudeInstalled
        self.codexInstalled = codexInstalled
    }
}

public final class AgentConnectionInstaller {
    public let appSupportURL: URL
    public let bridgeURL: URL
    public let claudeSettingsURL: URL
    public let codexConfigURL: URL

    private let now: () -> Date
    private let fileManager: FileManager

    public init(
        appSupportURL: URL = AgentConnectionInstaller.defaultAppSupportURL(),
        bridgeURL: URL = EventBridge.defaultFileURL(),
        claudeSettingsURL: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude", isDirectory: true)
            .appendingPathComponent("settings.json"),
        codexConfigURL: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex", isDirectory: true)
            .appendingPathComponent("config.toml"),
        now: @escaping () -> Date = Date.init,
        fileManager: FileManager = .default
    ) {
        self.appSupportURL = appSupportURL
        self.bridgeURL = bridgeURL
        self.claudeSettingsURL = claudeSettingsURL
        self.codexConfigURL = codexConfigURL
        self.now = now
        self.fileManager = fileManager
    }

    public static func defaultAppSupportURL() -> URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        return support.appendingPathComponent("Greenlight", isDirectory: true)
    }

    public func status() -> AgentConnectionStatus {
        let eventScriptPath = eventScriptURL.path
        let jsonEscapedEventScriptPath = eventScriptPath.replacingOccurrences(of: "/", with: "\\/")
        let codexScriptPath = codexNotifyScriptURL.path

        let claudeText = (try? String(contentsOf: claudeSettingsURL, encoding: .utf8)) ?? ""
        let codexText = (try? String(contentsOf: codexConfigURL, encoding: .utf8)) ?? ""

        return AgentConnectionStatus(
            claudeInstalled: claudeText.contains(eventScriptPath) || claudeText.contains(jsonEscapedEventScriptPath),
            codexInstalled: codexText.contains(codexScriptPath)
        )
    }

    public func sendTestEvent(tool: AgentTool, project: String = "Greenlight test") throws -> ConnectionInstallResult {
        try fileManager.createDirectory(at: bridgeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let event = GreenlightEvent(
            id: "greenlight-test-\(tool.rawValue)",
            tool: tool,
            project: project,
            state: .needsInput,
            timestamp: now(),
            jumpTarget: nil
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(event)
        let line = Data(data + Data("\n".utf8))

        if fileManager.fileExists(atPath: bridgeURL.path) {
            let handle = try FileHandle(forWritingTo: bridgeURL)
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: line)
        } else {
            try line.write(to: bridgeURL)
        }

        return ConnectionInstallResult(installed: true, message: "Sent a Greenlight test signal.")
    }

    public func installClaude() throws -> ConnectionInstallResult {
        try installHelperScripts()
        try fileManager.createDirectory(at: claudeSettingsURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let backup = try backupFileIfPresent(claudeSettingsURL)

        let settings = try readClaudeSettings()
        let updated = settingsByInstallingClaudeHooks(settings)
        let data = try JSONSerialization.data(withJSONObject: updated, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: claudeSettingsURL)

        return ConnectionInstallResult(installed: true, message: "Claude Code is connected to Greenlight.", backupURL: backup)
    }

    public func installCodex() throws -> ConnectionInstallResult {
        try installHelperScripts()
        try fileManager.createDirectory(at: codexConfigURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let backup = try backupFileIfPresent(codexConfigURL)

        let existing = (try? String(contentsOf: codexConfigURL, encoding: .utf8)) ?? ""
        let previousNotify = parseNotifyArray(from: existing)
        try writeCodexNotifyWrapper(previousNotify: previousNotify)

        let notifyLine = "notify = [\"\(escapeTomlString(codexNotifyScriptURL.path))\"]"
        let updated: String
        if existing.range(of: #"(?m)^notify\s*=\s*\[.*\]\s*$"#, options: .regularExpression) != nil {
            updated = existing.replacingOccurrences(
                of: #"(?m)^notify\s*=\s*\[.*\]\s*$"#,
                with: notifyLine,
                options: .regularExpression
            )
        } else {
            let separator = existing.hasSuffix("\n") || existing.isEmpty ? "" : "\n"
            updated = "\(existing)\(separator)\(notifyLine)\n"
        }

        try updated.write(to: codexConfigURL, atomically: true, encoding: .utf8)

        return ConnectionInstallResult(installed: true, message: "Codex is connected to Greenlight.", backupURL: backup)
    }

    private var eventScriptURL: URL {
        appSupportURL.appendingPathComponent("greenlight-event.sh")
    }

    private var codexNotifyScriptURL: URL {
        appSupportURL.appendingPathComponent("greenlight-codex-notify.sh")
    }

    private func installHelperScripts() throws {
        try fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        try eventScriptContents().write(to: eventScriptURL, atomically: true, encoding: .utf8)
        try setExecutable(eventScriptURL)
    }

    private func writeCodexNotifyWrapper(previousNotify: [String]) throws {
        let previousCommand: String
        if previousNotify.isEmpty || previousNotify.first == codexNotifyScriptURL.path {
            previousCommand = ""
        } else {
            previousCommand = previousNotify.map(shellQuote).joined(separator: " ") + #" "$@""#
        }

        let contents = """
        #!/bin/zsh
        set +e
        \(previousCommand)
        \(shellQuote(eventScriptURL.path)) codex needsInput "${PWD##*/}"
        exit 0
        """

        try contents.write(to: codexNotifyScriptURL, atomically: true, encoding: .utf8)
        try setExecutable(codexNotifyScriptURL)
    }

    private func eventScriptContents() -> String {
        """
        #!/bin/zsh
        set +e

        BRIDGE=\(shellQuote(bridgeURL.path))
        TOOL="${1:-other}"
        STATE="${2:-needsInput}"
        PROJECT="${3:-${PWD##*/}}"
        SESSION_ID="${GREENLIGHT_SESSION_ID:-$TOOL:$PWD}"
        JUMP_TARGET="${GREENLIGHT_JUMP_TARGET:-$PWD}"
        TIMESTAMP="$(/bin/date -u +"%Y-%m-%dT%H:%M:%SZ")"

        json_escape() {
          printf "%s" "$1" | /usr/bin/sed 's/\\\\/\\\\\\\\/g; s/"/\\\\"/g'
        }

        /bin/mkdir -p "$(/usr/bin/dirname "$BRIDGE")"
        /usr/bin/printf '{"id":"%s","tool":"%s","project":"%s","state":"%s","timestamp":"%s","jumpTarget":"%s"}\\n' \
          "$(json_escape "$SESSION_ID")" \
          "$(json_escape "$TOOL")" \
          "$(json_escape "$PROJECT")" \
          "$(json_escape "$STATE")" \
          "$(json_escape "$TIMESTAMP")" \
          "$(json_escape "$JUMP_TARGET")" >> "$BRIDGE"
        """
    }

    private func readClaudeSettings() throws -> [String: Any] {
        guard fileManager.fileExists(atPath: claudeSettingsURL.path) else {
            return [:]
        }

        let data = try Data(contentsOf: claudeSettingsURL)
        guard !data.isEmpty else {
            return [:]
        }

        return (try JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }

    private func settingsByInstallingClaudeHooks(_ settings: [String: Any]) -> [String: Any] {
        var updated = settings
        var hooks = (settings["hooks"] as? [String: Any]) ?? [:]

        installClaudeHook(event: "SessionStart", state: "running", into: &hooks)
        installClaudeHook(event: "Notification", state: "needsInput", into: &hooks)
        installClaudeHook(event: "Stop", state: "done", into: &hooks)
        installClaudeHook(event: "StopFailure", state: "blocked", into: &hooks)

        updated["hooks"] = hooks
        return updated
    }

    private func installClaudeHook(event: String, state: String, into hooks: inout [String: Any]) {
        var groups = (hooks[event] as? [[String: Any]]) ?? []
        groups.removeAll { group in
            guard let hookItems = group["hooks"] as? [[String: Any]] else {
                return false
            }
            return hookItems.contains { item in
                (item["command"] as? String)?.contains(eventScriptURL.path) == true
            }
        }

        groups.append([
            "matcher": "",
            "hooks": [[
                "type": "command",
                "command": "\(shellQuote(eventScriptURL.path)) claude \(state)"
            ]]
        ])
        hooks[event] = groups
    }

    private func backupFileIfPresent(_ url: URL) throws -> URL? {
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let stamp = formatter.string(from: now()).replacingOccurrences(of: ":", with: "-")
        let backupURL = url.deletingLastPathComponent()
            .appendingPathComponent("\(url.lastPathComponent).greenlight-backup-\(stamp)")

        if fileManager.fileExists(atPath: backupURL.path) {
            try fileManager.removeItem(at: backupURL)
        }
        try fileManager.copyItem(at: url, to: backupURL)
        return backupURL
    }

    private func parseNotifyArray(from toml: String) -> [String] {
        guard
            let line = toml
                .split(separator: "\n", omittingEmptySubsequences: false)
                .map(String.init)
                .first(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("notify") }),
            let equalsIndex = line.firstIndex(of: "=")
        else {
            return []
        }

        let value = String(line[line.index(after: equalsIndex)...]).trimmingCharacters(in: .whitespaces)
        guard value.hasPrefix("[") else {
            return []
        }

        var values: [String] = []
        var current = ""
        var insideString = false
        var isEscaped = false

        for character in value {
            if isEscaped {
                current.append(character)
                isEscaped = false
                continue
            }

            if character == "\\" {
                isEscaped = true
                continue
            }

            if character == "\"" {
                if insideString {
                    values.append(current)
                    current = ""
                    insideString = false
                } else {
                    insideString = true
                }
                continue
            }

            if insideString {
                current.append(character)
            }
        }

        return values
    }

    private func escapeTomlString(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    private func shellQuote(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private func setExecutable(_ url: URL) throws {
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
    }
}
