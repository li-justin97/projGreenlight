# Greenlight Agent Connections Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a local, reversible setup flow that connects Greenlight to Claude Code and Codex by installing hook commands that append events to Greenlight's JSONL bridge.

**Architecture:** Put config-editing and helper-script generation in `GreenlightCore` so it can be tested without launching the app. The SwiftUI onboarding and preferences screens call that installer and display connection status, while the existing `EventBridge` continues to feed the UI.

**Tech Stack:** Swift, Swift Testing, SwiftUI/AppKit, local JSON/TOML text config, shell helper scripts.

---

### Task 1: Add Tested Installer Core

**Files:**
- Create: `Sources/GreenlightCore/AgentConnectionInstaller.swift`
- Test: `Tests/GreenlightCoreTests/AgentConnectionInstallerTests.swift`

- [ ] Write failing tests for helper script generation, Claude settings install, Codex notify install, backups, and test events.
- [ ] Run `swift test --disable-sandbox --cache-path .build/swiftpm-cache --filter AgentConnectionInstallerTests` and confirm failures are from missing installer types.
- [ ] Implement `AgentConnectionInstaller`, `ConnectionInstallResult`, and `AgentConnectionStatus`.
- [ ] Re-run installer tests and then the full suite.

### Task 2: Wire Installer Into App UI

**Files:**
- Modify: `Sources/GreenlightApp/GreenlightAppController.swift`
- Modify: `Sources/GreenlightApp/Views/PopoverView.swift`
- Modify: `Sources/GreenlightApp/Views/PreferencesView.swift`

- [ ] Add controller actions for installing Claude, installing Codex, sending a test signal, and opening configs.
- [ ] Replace onboarding mock toggles with connection buttons and status messages.
- [ ] Add a preferences section for reconnecting and sending a test event after onboarding.
- [ ] Keep demo controls available but turn demo mode off after a successful install or test event.

### Task 3: Package And Verify

**Files:**
- Modify: `README.md`

- [ ] Document that Greenlight connects through local Claude/Codex hooks and backs up config files before editing.
- [ ] Run `swift test --disable-sandbox --cache-path .build/swiftpm-cache`.
- [ ] Run `scripts/package-app.sh`.
- [ ] Run `codesign --verify --verbose outputs/Greenlight.app`.
- [ ] Commit and push the changes after verification.

