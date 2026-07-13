import SwiftUI

struct PreferencesView: View {
    @ObservedObject var settings: AppSettings
    let bridgePath: String

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
    }
}
