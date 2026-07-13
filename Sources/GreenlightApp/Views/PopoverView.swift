import GreenlightCore
import SwiftUI

struct PopoverView: View {
    @ObservedObject var store: SessionStore
    @ObservedObject var settings: AppSettings

    let bridgePath: String
    let onOpenPreferences: () -> Void
    let onRegisterSession: () -> Void
    let onJump: (AgentSession) -> Void
    let onDemoAction: (DemoAction) -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if !settings.onboardingComplete {
                OnboardingView(settings: settings, bridgePath: bridgePath)
            } else {
                HeaderView(status: store.aggregateStatus, summary: summaryLine, playfulMascot: settings.playfulMascot)
                    .padding(.horizontal, 16)
                    .padding(.top, 15)
                    .padding(.bottom, 13)

                Divider()

                if store.sessions.isEmpty {
                    EmptyStateView(bridgePath: bridgePath, onRegisterSession: onRegisterSession)
                        .frame(maxWidth: .infinity, minHeight: 190)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(store.sessions) { session in
                                SessionRow(session: session, onJump: { onJump(session) })
                            }
                        }
                        .padding(6)
                    }
                    .frame(maxHeight: 340)
                }

                Divider()

                FooterView(
                    onRegisterSession: onRegisterSession,
                    onOpenPreferences: onOpenPreferences,
                    onQuit: onQuit
                )
            }
        }
        .frame(width: 372)
        .background(.regularMaterial)
    }

    private var summaryLine: String {
        let attention = store.sessions.filter { $0.state == .needsInput || $0.state == .blocked || $0.escalated }.count
        let running = store.sessions.filter { $0.state == .running }.count

        if attention > 0 {
            return "\(attention) need\(attention == 1 ? "s" : "") you · \(running) running"
        }

        if store.sessions.contains(where: { $0.state == .done }) {
            return "All clear · work just finished"
        }

        return "All clear · \(store.sessions.count) active"
    }
}

enum DemoAction {
    case playLoop
    case needsInput
    case blocked
    case done
    case clear
}

private struct HeaderView: View {
    let status: AggregateStatus
    let summary: String
    let playfulMascot: Bool

    var body: some View {
        HStack(spacing: 13) {
            if playfulMascot {
                MascotView(status: status)
            } else {
                Circle()
                    .fill(status.color)
                    .frame(width: 13, height: 13)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13.5, weight: .semibold))
                Text(summary)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var title: String {
        switch status {
        case .red: return "Something needs you now."
        case .yellow: return "A session is waiting on you."
        case .green: return "All clear. Carry on."
        case .done: return "Nice, work just wrapped up."
        case .gray: return "No active sessions yet."
        }
    }
}

private struct MascotView: View {
    let status: AggregateStatus
    @State private var isRaised = false

    private let size: CGFloat = 46

    var body: some View {
        VStack(spacing: gap) {
            light(.red, lamp: .red)
            light(.orange, lamp: .yellow)
            light(.green, lamp: .green)
        }
        .frame(width: bodyWidth)
        .padding(shellPadding)
        .background(
            RoundedRectangle(cornerRadius: shellRadius)
                .fill(LinearGradient(colors: [.black.opacity(0.72), .black.opacity(0.86)], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .offset(y: bobOffset)
        .animation(bobAnimation, value: isRaised)
        .onAppear {
            guard presentation.bobbing != .still else {
                return
            }
            isRaised = true
        }
        .onChange(of: presentation.bobbing) { newValue in
            isRaised = newValue != .still
        }
    }

    private var presentation: MascotPresentation {
        status.mascotPresentation
    }

    private var lampDiameter: CGFloat {
        size * 0.62
    }

    private var gap: CGFloat {
        size * 0.12
    }

    private var shellPadding: CGFloat {
        size * 0.16
    }

    private var shellRadius: CGFloat {
        size * 0.34
    }

    private var bodyWidth: CGFloat {
        size + size * 0.36
    }

    private var bobOffset: CGFloat {
        guard presentation.bobbing != .still else {
            return 0
        }

        return isRaised ? -2.5 : 0
    }

    private var bobAnimation: Animation? {
        switch presentation.bobbing {
        case .gentle:
            return .easeInOut(duration: 1.6).repeatForever(autoreverses: true)
        case .urgent:
            return .easeInOut(duration: 0.45).repeatForever(autoreverses: true)
        case .still:
            return nil
        }
    }

    private func light(_ color: Color, lamp: MascotLamp) -> some View {
        let active = presentation.activeLamp == lamp

        return ZStack {
            Circle()
                .fill(active ? color : Color.white.opacity(0.14))
                .frame(width: lampDiameter, height: lampDiameter)
                .shadow(color: active ? color.opacity(0.8) : .clear, radius: size * 0.11)

            if active {
                FaceView(expression: presentation.expression, lampDiameter: lampDiameter)
            }
        }
            .frame(width: lampDiameter, height: lampDiameter)
    }
}

private struct FaceView: View {
    let expression: MascotExpression
    let lampDiameter: CGFloat

    var body: some View {
        VStack(spacing: lampDiameter * 0.08) {
            HStack(spacing: lampDiameter * 0.16) {
                Capsule()
                    .fill(Color.black.opacity(0.72))
                    .frame(width: lampDiameter * 0.15, height: eyeHeight)
                Capsule()
                    .fill(Color.black.opacity(0.72))
                    .frame(width: lampDiameter * 0.15, height: eyeHeight)
            }

            mouth
                .stroke(Color.black.opacity(0.72), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: lampDiameter * 0.4, height: lampDiameter * 0.2)
        }
    }

    private var eyeHeight: CGFloat {
        expression == .sleepy ? lampDiameter * 0.08 : lampDiameter * 0.19
    }

    private var mouth: Path {
        var path = Path()
        let width = lampDiameter * 0.4
        let height = lampDiameter * 0.2
        switch expression {
        case .happy:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addQuadCurve(to: CGPoint(x: width, y: 0), control: CGPoint(x: width / 2, y: height * 1.25))
        case .flat, .sleepy:
            path.move(to: CGPoint(x: width * 0.08, y: height * 0.55))
            path.addLine(to: CGPoint(x: width * 0.92, y: height * 0.55))
        case .worried:
            path.move(to: CGPoint(x: 0, y: height))
            path.addQuadCurve(to: CGPoint(x: width, y: height), control: CGPoint(x: width / 2, y: -height * 0.25))
        }
        return path
    }
}

private struct SessionRow: View {
    let session: AgentSession
    let onJump: () -> Void

    var body: some View {
        HStack(spacing: 11) {
            ZStack(alignment: .bottomTrailing) {
                Text(session.tool.tag)
                    .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color.secondary.opacity(0.11))
                    .clipShape(RoundedRectangle(cornerRadius: 9))

                Circle()
                    .fill(stateColor)
                    .frame(width: 9, height: 9)
                    .overlay(Circle().stroke(.background, lineWidth: 2))
                    .offset(x: 2, y: 2)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(session.project)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .lineLimit(1)
                Text("\(session.tool.displayName) · \(relativeTime)")
                    .font(.system(size: 11))
                    .foregroundStyle(sessionNeedsAttention ? stateColor : .secondary)
            }

            Spacer()

            Text(stateLabel)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(stateColor)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(stateColor.opacity(0.14))
                .clipShape(Capsule())

            Button(action: onJump) {
                Image(systemName: "arrow.up.forward")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .disabled(session.jumpTarget == nil && !sessionNeedsAttention)
            .help("Jump to session")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(session.escalated ? Color.red.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var sessionNeedsAttention: Bool {
        session.state == .needsInput || session.state == .blocked || session.escalated
    }

    private var stateLabel: String {
        if session.escalated {
            return "Waiting"
        }

        switch session.state {
        case .running: return "Running"
        case .needsInput: return "Needs input"
        case .blocked: return "Blocked"
        case .done: return "Done"
        case .idle: return "Idle"
        }
    }

    private var stateColor: Color {
        if session.escalated {
            return .red
        }

        switch session.state {
        case .running: return .green
        case .needsInput: return .orange
        case .blocked: return .red
        case .done: return .blue
        case .idle: return .gray
        }
    }

    private var relativeTime: String {
        let seconds = max(0, Int(Date().timeIntervalSince(session.since)))
        if seconds < 10 { return "just now" }
        if seconds < 60 { return "\(seconds)s ago" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m ago" }
        return "\(minutes / 60)h ago"
    }
}

private extension AggregateStatus {
    var color: Color {
        switch self {
        case .red: return .red
        case .yellow: return .orange
        case .green: return .green
        case .done: return .blue
        case .gray: return .gray
        }
    }
}

private struct EmptyStateView: View {
    let bridgePath: String
    let onRegisterSession: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("No active sessions")
                .font(.headline)
            Text("Greenlight is watching this bridge file for agent updates.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text(bridgePath)
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)
            Button("Register session", action: onRegisterSession)
        }
        .padding(22)
    }
}

private struct FooterView: View {
    let onRegisterSession: () -> Void
    let onOpenPreferences: () -> Void
    let onQuit: () -> Void

    var body: some View {
        HStack {
            Button("＋ Register session", action: onRegisterSession)
                .buttonStyle(.borderless)
            Spacer()
            Button("Preferences...", action: onOpenPreferences)
                .buttonStyle(.borderless)
            Button("Quit", action: onQuit)
                .buttonStyle(.borderless)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 9)
        .font(.system(size: 11.5))
    }
}

private struct OnboardingView: View {
    @ObservedObject var settings: AppSettings
    let bridgePath: String
    @State private var selectedClaude = true
    @State private var selectedCodex = true

    var body: some View {
        VStack(spacing: 16) {
            MascotView(status: .yellow)
                .scaleEffect(1.4)
                .padding(.top, 18)
            VStack(spacing: 6) {
                Text("Greenlight")
                    .font(.title3.bold())
                Text("A calm light in your menu bar that tells you when Claude, Codex, or any agent needs you.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 8) {
                Toggle("Claude Code", isOn: $selectedClaude)
                Toggle("Codex", isOn: $selectedCodex)
                Text("Bridge file:")
                    .font(.caption.bold())
                    .padding(.top, 4)
                Text(bridgePath)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            .padding(12)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button("Open Greenlight") {
                settings.onboardingComplete = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(22)
    }
}
