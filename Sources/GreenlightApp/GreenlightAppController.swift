import AppKit
import Combine
import GreenlightCore
import SwiftUI

@MainActor
final class GreenlightAppController: NSObject, NSApplicationDelegate {
    private let store = SessionStore()
    private let bridge = EventBridge()
    private let connectionInstaller = AgentConnectionInstaller()
    private let settings = AppSettings()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private var refreshTimer: Timer?
    private var bridgeTimer: Timer?
    private var demoTimers: [Timer] = []
    private var preferencesWindow: NSWindow?
    private var cancellables: Set<AnyCancellable> = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureStatusItem()
        configurePopover()
        if settings.demoMode {
            store.seedDemoSessions()
        }
        updateStatusItem()
        startTimers()
        observeSettings()
    }

    func applicationWillTerminate(_ notification: Notification) {
        refreshTimer?.invalidate()
        bridgeTimer?.invalidate()
        demoTimers.forEach { $0.invalidate() }
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.target = self
        button.action = #selector(togglePopover)
        button.imagePosition = .imageLeft
        button.font = .monospacedSystemFont(ofSize: 12, weight: .semibold)
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 372, height: 430)
        popover.contentViewController = NSHostingController(
            rootView: PopoverView(
                store: store,
                settings: settings,
                bridgePath: bridge.fileURL.path,
                connectionStatus: connectionInstaller.status(),
                onRefreshConnectionStatus: { [weak self] in self?.connectionInstaller.status() ?? AgentConnectionStatus(claudeInstalled: false, codexInstalled: false) },
                onConnectClaude: { [weak self] in self?.installClaudeConnection() ?? ConnectionInstallResult(installed: false, message: "Greenlight is still starting up.") },
                onConnectCodex: { [weak self] in self?.installCodexConnection() ?? ConnectionInstallResult(installed: false, message: "Greenlight is still starting up.") },
                onSendTestSignal: { [weak self] in self?.sendConnectionTestSignal() ?? ConnectionInstallResult(installed: false, message: "Greenlight is still starting up.") },
                onOpenPreferences: { [weak self] in self?.openPreferences() },
                onRegisterSession: { [weak self] in self?.revealBridgeFile() },
                onJump: { [weak self] session in self?.jump(to: session) },
                onDemoAction: { [weak self] action in self?.handleDemoAction(action) },
                onQuit: { NSApp.terminate(nil) }
            )
        )
    }

    private func startTimers() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.store.refreshEscalation(escalationDelay: self?.settings.escalationDelay ?? 600)
                self?.updateStatusItem()
            }
        }

        bridgeTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.pollBridge()
            }
        }
    }

    private func observeSettings() {
        settings.objectWillChange
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateStatusItem()
                }
            }
            .store(in: &cancellables)
    }

    private func pollBridge() {
        do {
            for event in try bridge.poll() {
                store.apply(event: event)
            }
            updateStatusItem()
        } catch {
            updateStatusItem()
        }
    }

    private func updateStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        let status = store.aggregateStatus
        let count = store.sessions.filter { $0.state == .needsInput || $0.state == .blocked }.count
        button.image = StatusIcon.image(for: status)
        button.title = settings.showCount && count > 0 ? " \(count)" : ""
        button.toolTip = tooltip(for: status, count: count)
    }

    private func openPreferences() {
        if let preferencesWindow {
            preferencesWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let controller = NSHostingController(
            rootView: PreferencesView(
                settings: settings,
                bridgePath: bridge.fileURL.path,
                connectionStatus: connectionInstaller.status(),
                onRefreshConnectionStatus: { [weak self] in self?.connectionInstaller.status() ?? AgentConnectionStatus(claudeInstalled: false, codexInstalled: false) },
                onConnectClaude: { [weak self] in self?.installClaudeConnection() ?? ConnectionInstallResult(installed: false, message: "Greenlight is still starting up.") },
                onConnectCodex: { [weak self] in self?.installCodexConnection() ?? ConnectionInstallResult(installed: false, message: "Greenlight is still starting up.") },
                onSendTestSignal: { [weak self] in self?.sendConnectionTestSignal() ?? ConnectionInstallResult(installed: false, message: "Greenlight is still starting up.") }
            )
        )
        let window = NSWindow(contentViewController: controller)
        window.title = "Greenlight Preferences"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()
        preferencesWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func revealBridgeFile() {
        do {
            try bridge.ensureFileExists()
            NSWorkspace.shared.activateFileViewerSelecting([bridge.fileURL])
        } catch {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(bridge.fileURL.path, forType: .string)
        }
    }

    private func installClaudeConnection() -> ConnectionInstallResult {
        do {
            let result = try connectionInstaller.installClaude()
            settings.demoMode = false
            store.clearDemoSessions()
            return result
        } catch {
            return ConnectionInstallResult(installed: false, message: "Could not connect Claude Code: \(error.localizedDescription)")
        }
    }

    private func installCodexConnection() -> ConnectionInstallResult {
        do {
            let result = try connectionInstaller.installCodex()
            settings.demoMode = false
            store.clearDemoSessions()
            return result
        } catch {
            return ConnectionInstallResult(installed: false, message: "Could not connect Codex: \(error.localizedDescription)")
        }
    }

    private func sendConnectionTestSignal() -> ConnectionInstallResult {
        do {
            let result = try connectionInstaller.sendTestEvent(tool: .codex, project: "Greenlight test")
            settings.demoMode = false
            pollBridge()
            return result
        } catch {
            return ConnectionInstallResult(installed: false, message: "Could not send test signal: \(error.localizedDescription)")
        }
    }

    private func jump(to session: AgentSession) {
        if let jumpTarget = session.jumpTarget {
            let url = URL(fileURLWithPath: jumpTarget)
            NSWorkspace.shared.open(url)
        }

        store.apply(
            event: GreenlightEvent(
                id: session.id,
                tool: session.tool,
                project: session.project,
                state: .running,
                timestamp: Date(),
                jumpTarget: session.jumpTarget
            )
        )
        updateStatusItem()
    }

    private func handleDemoAction(_ action: DemoAction) {
        switch action {
        case .playLoop:
            playDemoLoop()
        case .needsInput:
            simulateFirstMatching(state: .running, newState: .needsInput)
        case .blocked:
            simulateFirstMatching(state: .running, newState: .blocked)
        case .done:
            simulateFirstMatching(state: .running, newState: .done)
        case .clear:
            store.seedDemoSessions()
        }
        updateStatusItem()
    }

    private func simulateFirstMatching(state: SessionState, newState: SessionState) {
        guard let session = store.sessions.first(where: { $0.state == state }) else {
            return
        }

        store.apply(
            event: GreenlightEvent(
                id: session.id,
                tool: session.tool,
                project: session.project,
                state: newState,
                timestamp: Date(),
                jumpTarget: session.jumpTarget
            )
        )
    }

    private func playDemoLoop() {
        demoTimers.forEach { $0.invalidate() }
        demoTimers.removeAll()

        let now = Date()
        store.clearDemoSessions()
        store.apply(event: GreenlightEvent(id: "loop-claude", tool: .claude, project: "project-greenlight", state: .running, timestamp: now, jumpTarget: nil))
        store.apply(event: GreenlightEvent(id: "loop-codex", tool: .codex, project: "api-refactor", state: .running, timestamp: now.addingTimeInterval(-140), jumpTarget: nil))

        scheduleDemo(after: 2) { [weak self] in
            self?.store.apply(event: GreenlightEvent(id: "loop-claude", tool: .claude, project: "project-greenlight", state: .needsInput, timestamp: Date(), jumpTarget: nil))
            self?.updateStatusItem()
        }

        scheduleDemo(after: 5) { [weak self] in
            self?.store.refreshEscalation(now: Date().addingTimeInterval(1_000), escalationDelay: 1)
            self?.updateStatusItem()
        }

        scheduleDemo(after: 8) { [weak self] in
            guard let self, let button = self.statusItem.button, !self.popover.isShown else {
                return
            }
            self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }

        scheduleDemo(after: 11) { [weak self] in
            self?.store.apply(event: GreenlightEvent(id: "loop-claude", tool: .claude, project: "project-greenlight", state: .running, timestamp: Date(), jumpTarget: nil))
            self?.updateStatusItem()
        }
    }

    private func scheduleDemo(after delay: TimeInterval, action: @escaping @MainActor () -> Void) {
        let timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            Task { @MainActor in action() }
        }
        demoTimers.append(timer)
    }

    private func tooltip(for status: AggregateStatus, count: Int) -> String {
        switch status {
        case .red:
            return "Greenlight: something needs you now"
        case .yellow:
            return "Greenlight: \(count) session\(count == 1 ? "" : "s") waiting"
        case .green:
            return "Greenlight: all active sessions running"
        case .done:
            return "Greenlight: work finished"
        case .gray:
            return "Greenlight: no active sessions"
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else {
            return
        }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}

private enum StatusIcon {
    static func image(for status: AggregateStatus) -> NSImage {
        let size = NSSize(width: 14, height: 14)
        let image = NSImage(size: size)
        image.lockFocus()
        color(for: status).setFill()
        NSBezierPath(ovalIn: NSRect(x: 2, y: 2, width: 10, height: 10)).fill()
        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    private static func color(for status: AggregateStatus) -> NSColor {
        switch status {
        case .red: .systemRed
        case .yellow: .systemOrange
        case .green: .systemGreen
        case .done: .systemBlue
        case .gray: .systemGray
        }
    }
}
