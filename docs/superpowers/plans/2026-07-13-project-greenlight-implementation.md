# Project Greenlight Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first native macOS menu bar version of Project Greenlight with a working status popover, demo state loop, preferences, and a tested local JSONL event bridge.

**Architecture:** Use a Swift Package with two targets: `GreenlightCore` for tested session state and event parsing, and `GreenlightApp` for the native AppKit/SwiftUI menu bar executable. The app reads all session status through a `SessionStore`, so demo events and real JSONL bridge events update the same UI.

**Tech Stack:** Swift Package Manager, Swift 5.9+, AppKit, SwiftUI, XCTest.

---

## File Structure

- Create `Package.swift`: package definition with `GreenlightCore`, `GreenlightApp`, and tests.
- Create `Sources/GreenlightCore/AgentSession.swift`: session model, states, aggregate status, display helpers.
- Create `Sources/GreenlightCore/SessionStore.swift`: observable session storage, escalation logic, event application, demo helpers.
- Create `Sources/GreenlightCore/GreenlightEvent.swift`: JSONL event model and decoding.
- Create `Sources/GreenlightCore/EventBridge.swift`: bridge file location, file creation, incremental JSONL polling.
- Create `Sources/GreenlightApp/main.swift`: AppKit app entry point and menu bar controller.
- Create `Sources/GreenlightApp/GreenlightAppController.swift`: status item, popover lifecycle, timers.
- Create `Sources/GreenlightApp/Views/PopoverView.swift`: SwiftUI popover UI.
- Create `Sources/GreenlightApp/Views/PreferencesView.swift`: settings/onboarding/demo controls.
- Create `Tests/GreenlightCoreTests/AgentSessionTests.swift`: aggregate state and relative display tests.
- Create `Tests/GreenlightCoreTests/EventBridgeTests.swift`: JSONL parsing and bridge ingestion tests.
- Create `Tests/GreenlightCoreTests/SessionStoreTests.swift`: event application and escalation tests.

## Task 1: Create Swift Package Skeleton

**Files:**
- Create: `Package.swift`
- Create: `Sources/GreenlightCore/AgentSession.swift`
- Create: `Tests/GreenlightCoreTests/AgentSessionTests.swift`

- [ ] **Step 1: Write failing aggregate-status tests**

Create `Tests/GreenlightCoreTests/AgentSessionTests.swift`:

```swift
import XCTest
@testable import GreenlightCore

final class AgentSessionTests: XCTestCase {
    func testAggregateStatusIsRedWhenBlockedSessionExists() {
        let sessions = [
            AgentSession(id: "1", tool: .claude, project: "alpha", state: .running, since: Date()),
            AgentSession(id: "2", tool: .codex, project: "beta", state: .blocked, since: Date())
        ]

        XCTAssertEqual(AggregateStatus.resolve(from: sessions), .red)
    }

    func testAggregateStatusIsYellowWhenInputIsNeeded() {
        let sessions = [
            AgentSession(id: "1", tool: .claude, project: "alpha", state: .needsInput, since: Date())
        ]

        XCTAssertEqual(AggregateStatus.resolve(from: sessions), .yellow)
    }

    func testAggregateStatusIsGrayWhenNoSessionsExist() {
        XCTAssertEqual(AggregateStatus.resolve(from: []), .gray)
    }
}
```

- [ ] **Step 2: Run tests and verify failure**

Run: `swift test --filter AgentSessionTests`

Expected: fail because the package and `GreenlightCore` types do not exist yet.

- [ ] **Step 3: Add minimal package and model implementation**

Create `Package.swift` and `Sources/GreenlightCore/AgentSession.swift` with the model, state enum, and aggregate resolver.

- [ ] **Step 4: Run tests and verify pass**

Run: `swift test --filter AgentSessionTests`

Expected: pass.

## Task 2: Add Session Store and Escalation

**Files:**
- Create: `Sources/GreenlightCore/SessionStore.swift`
- Create: `Tests/GreenlightCoreTests/SessionStoreTests.swift`

- [ ] **Step 1: Write failing store tests**

Test that applying a `needsInput` event creates or updates a session, and that a waiting session escalates after the configured delay.

- [ ] **Step 2: Run tests and verify failure**

Run: `swift test --filter SessionStoreTests`

Expected: fail because `SessionStore` does not exist.

- [ ] **Step 3: Implement session store**

Add an `ObservableObject` store with `@Published private(set) var sessions`, `apply(event:)`, `refreshEscalation(now:)`, `clearDemoSessions()`, and `seedDemoSessions(now:)`.

- [ ] **Step 4: Run tests and verify pass**

Run: `swift test --filter SessionStoreTests`

Expected: pass.

## Task 3: Add JSONL Event Bridge

**Files:**
- Create: `Sources/GreenlightCore/GreenlightEvent.swift`
- Create: `Sources/GreenlightCore/EventBridge.swift`
- Create: `Tests/GreenlightCoreTests/EventBridgeTests.swift`

- [ ] **Step 1: Write failing event bridge tests**

Test decoding a valid JSON line into a `GreenlightEvent`, ignoring invalid lines, and reading only newly appended bridge lines on subsequent polls.

- [ ] **Step 2: Run tests and verify failure**

Run: `swift test --filter EventBridgeTests`

Expected: fail because event parsing and bridge types do not exist.

- [ ] **Step 3: Implement event model and bridge**

Add a `GreenlightEvent` decoder and an `EventBridge` that creates the bridge file and tracks read offset between polls.

- [ ] **Step 4: Run tests and verify pass**

Run: `swift test --filter EventBridgeTests`

Expected: pass.

## Task 4: Create Native Menu Bar Shell

**Files:**
- Create: `Sources/GreenlightApp/main.swift`
- Create: `Sources/GreenlightApp/GreenlightAppController.swift`

- [ ] **Step 1: Add app target files**

Create an AppKit entry point that starts `NSApplication`, creates an `NSStatusItem`, and opens an `NSPopover` from the menu bar item.

- [ ] **Step 2: Build app target**

Run: `swift build`

Expected: build succeeds and produces the `GreenlightApp` executable.

- [ ] **Step 3: Run app manually**

Run: `swift run GreenlightApp`

Expected: a menu bar item appears with a colored Greenlight status.

## Task 5: Build Popover UI

**Files:**
- Create: `Sources/GreenlightApp/Views/PopoverView.swift`

- [ ] **Step 1: Implement SwiftUI popover**

Add a compact popover with header, optional mascot, summary line, session rows, state pills, relative time, jump buttons, and footer actions.

- [ ] **Step 2: Build app target**

Run: `swift build`

Expected: build succeeds.

- [ ] **Step 3: Run manual UI check**

Run: `swift run GreenlightApp`

Expected: clicking the menu bar item shows the session list popover.

## Task 6: Add Preferences, Onboarding, and Demo Mode

**Files:**
- Create: `Sources/GreenlightApp/Views/PreferencesView.swift`
- Modify: `Sources/GreenlightApp/GreenlightAppController.swift`
- Modify: `Sources/GreenlightApp/Views/PopoverView.swift`

- [ ] **Step 1: Add settings model to app controller**

Track show-count, playful mascot, escalation delay, onboarding complete, and demo mode in app storage.

- [ ] **Step 2: Add preferences view**

Create controls for count visibility, playful mode, escalation delay, demo mode, and sample install commands for Claude/Codex.

- [ ] **Step 3: Wire footer actions**

Make "Register session" reveal the bridge file path and make "Preferences" open the settings window.

- [ ] **Step 4: Build and manually verify**

Run: `swift build` and `swift run GreenlightApp`.

Expected: preferences open and settings affect the popover/menu bar.

## Task 7: Wire Event Polling and Demo Loop

**Files:**
- Modify: `Sources/GreenlightApp/GreenlightAppController.swift`
- Modify: `Sources/GreenlightCore/SessionStore.swift`

- [ ] **Step 1: Poll bridge file**

Add a timer that polls the JSONL bridge file every second and applies new events to the store.

- [ ] **Step 2: Add demo loop actions**

Add controls or menu actions that simulate running, needs input, blocked, done, and clear.

- [ ] **Step 3: Verify with sample event**

Append a JSON event to the bridge file:

```bash
printf '%s\n' '{"id":"manual-test","tool":"claude","project":"manual-test","state":"needsInput","timestamp":"2026-07-13T13:41:00Z"}' >> "$HOME/Library/Application Support/Greenlight/events.jsonl"
```

Expected: Greenlight changes to yellow and shows the manual-test session.

## Task 8: Final Verification

**Files:**
- All created files.

- [ ] **Step 1: Run tests**

Run: `swift test`

Expected: all tests pass.

- [ ] **Step 2: Build app**

Run: `swift build`

Expected: build succeeds.

- [ ] **Step 3: Manual smoke test**

Run: `swift run GreenlightApp`, open the popover, toggle preferences, append a bridge event, and confirm the menu bar state updates.

Expected: the app is usable as a first local MVP.

## Self-Review

- Spec coverage: native menu bar shell, popover, onboarding/preferences, state engine, JSONL bridge, demo mode, and tests are covered.
- Scope intentionally excludes card layout, automatic hook installation, and notification scraping.
- Type names are consistent: `AgentSession`, `AgentTool`, `SessionState`, `AggregateStatus`, `GreenlightEvent`, `SessionStore`, and `EventBridge`.
