import GreenlightCore
import SwiftUI

struct PreferencesView: View {
    @ObservedObject var settings: AppSettings
    let bridgePath: String
    let connectionStatus: AgentConnectionStatus
    let onRefreshConnectionStatus: () -> AgentConnectionStatus
    let onConnectClaude: () -> ConnectionInstallResult
    let onConnectCodex: () -> ConnectionInstallResult
    let onSendTestSignal: () -> ConnectionInstallResult

    @State private var status: AgentConnectionStatus
    @State private var connectionMessage = "Connect Claude Code or Codex to send real status updates into Greenlight."

    init(
        settings: AppSettings,
        bridgePath: String,
        connectionStatus: AgentConnectionStatus,
        onRefreshConnectionStatus: @escaping () -> AgentConnectionStatus,
        onConnectClaude: @escaping () -> ConnectionInstallResult,
        onConnectCodex: @escaping () -> ConnectionInstallResult,
        onSendTestSignal: @escaping () -> ConnectionInstallResult
    ) {
        self.settings = settings
        self.bridgePath = bridgePath
        self.connectionStatus = connectionStatus
        self.onRefreshConnectionStatus = onRefreshConnectionStatus
        self.onConnectClaude = onConnectClaude
        self.onConnectCodex = onConnectCodex
        self.onSendTestSignal = onSendTestSignal
        _status = State(initialValue: connectionStatus)
    }

    var body: some View {
        Form {
            Section("Menu Bar") {
                Toggle("Show waiting count", isOn: $settings.showCount)
                Toggle("Playful mascot", isOn: $settings.playfulMascot)
            }

            Section("Reminder Timing") {
                Picker("Escalate after", selection: $settings.escalationDelay) {
                    Text("5 minutes").tag(TimeInterval(300))
                    Text("10 minutes").tag(TimeInterval(600))
                    Text("15 minutes").tag(TimeInterval(900))
                }
                .pickerStyle(.segmented)
            }

            Section("Demo") {
                Toggle("Show demo controls", isOn: $settings.demoMode)
            }

            Section("Agent Connections") {
                HStack {
                    Text("Claude Code")
                    Spacer()
                    Text(status.claudeInstalled ? "Connected" : "Not connected")
                        .foregroundStyle(status.claudeInstalled ? .green : .secondary)
                    Button(status.claudeInstalled ? "Reconnect" : "Connect") {
                        connectionMessage = onConnectClaude().message
                        status = onRefreshConnectionStatus()
                    }
                }

                HStack {
                    Text("Codex")
                    Spacer()
                    Text(status.codexInstalled ? "Connected" : "Not connected")
                        .foregroundStyle(status.codexInstalled ? .green : .secondary)
                    Button(status.codexInstalled ? "Reconnect" : "Connect") {
                        connectionMessage = onConnectCodex().message
                        status = onRefreshConnectionStatus()
                    }
                }

                Button("Send test signal") {
                    connectionMessage = onSendTestSignal().message
                    status = onRefreshConnectionStatus()
                }

                Text(connectionMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Agent Bridge") {
                Text(bridgePath)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                Text("Claude/Codex hooks can append JSONL events here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(18)
        .frame(width: 440)
        .onAppear {
            status = onRefreshConnectionStatus()
        }
    }
}
