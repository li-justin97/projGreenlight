# Project Greenlight Design

## Summary

Project Greenlight is a native macOS menu bar app that shows whether AI coding agents are running, waiting for input, finished, or blocked. Its core promise is simple: the user should be able to glance at the menu bar and know whether Claude, Codex, or another agent needs attention.

The first version will be a Swift/SwiftUI app that matches the provided mockup's interaction model: a colored menu bar status item, a compact popover with session rows, playful optional traffic-light personality, onboarding for Claude/Codex setup, and a demo mode for simulation.

## Goals

- Make agent state visible without requiring the user to switch apps.
- Preserve the mockup's calm, fun, Mac-native feeling.
- Build a real menu bar app rather than a web wrapper.
- Start with a reliable local event bridge for session updates.
- Include demo/simulation controls for development and pitching, but keep them out of the normal product surface.

## Non-Goals

- Build a full desktop dashboard.
- Support every AI agent tool in the first version.
- Scrape app notifications as the primary detection strategy.
- Ship cross-device sync.
- Implement deep Claude/Codex control beyond opening or surfacing the related session.

## Platform Choice

The app should be built as a native Swift/SwiftUI macOS menu bar app.

Reasons:

- macOS menu bar behavior is first-class through `MenuBarExtra` or `NSStatusItem`.
- SwiftUI can reproduce the popover UI with lower overhead than Electron.
- Native APIs make future features easier: login item, accessibility permissions, notification fallback, file watching, URL handling, and app/window activation.
- The product is intentionally small, so a heavy desktop shell would work against the feel.

## Main Surfaces

### Menu Bar Item

The menu bar item is the always-visible signal.

It should show:

- A colored status dot.
- An optional numeric count when sessions need attention.
- A hover/click target that opens the popover.

Aggregate state rules:

- Red: at least one session is blocked or one waiting session has escalated.
- Yellow: at least one session needs input.
- Green: at least one session is running and none need attention.
- Blue: at least one session is done and none are running or waiting.
- Gray: no active sessions are known.

### Popover

The popover opens from the menu bar item and shows the working state.

It should include:

- Header with either the playful traffic-light character or a plain "Greenlight" header.
- Summary text such as "2 need you · 3 running" or "All clear · 4 active."
- A list of sessions with tool, project, state, time since change, and jump action.
- Footer links for registering a session and opening preferences.

The mockup supports list and card layouts. The first build should implement the list layout only. Card layout should wait until after the state engine, event bridge, and menu bar loop are working.

### Onboarding

Onboarding should be a short three-step flow:

1. Welcome: explain the product in one sentence.
2. Connect agents: choose Claude Code and/or Codex.
3. Done: open Greenlight.

The "connect agents" step can initially show install commands rather than fully modifying shell config. It should make the integration path clear without taking risky automated setup steps too early.

### Preferences

Preferences can be minimal for the first build:

- Show count in menu bar: on/off.
- Playful mascot: on/off.
- Escalation time for waiting sessions.
- Demo mode: on/off.

## Session Model

Each tracked session should have:

- `id`: stable unique identifier.
- `tool`: `claude`, `codex`, or `other`.
- `project`: human-readable project/session name.
- `state`: `running`, `needsInput`, `blocked`, `done`, or `idle`.
- `since`: timestamp for when the state last changed.
- `escalated`: derived or stored flag for long-waiting sessions.
- `jumpTarget`: optional path, URL, command, or app hint used by the jump action.

The UI should treat session state as data. Demo sessions and real sessions should feed the same store.

## Local Event Bridge

The first reliable integration should be a local event bridge. Agent hooks can report session changes to Greenlight without Greenlight needing to inspect private app state.

Recommended MVP bridge:

- Watch a local JSONL file in the app support directory.
- Each line is a session event.
- Greenlight ingests new events and updates the session store.

Example event:

```json
{"id":"project-greenlight","tool":"claude","project":"project-greenlight","state":"needsInput","jumpTarget":"/Users/justin.li/work/project-greenlight","timestamp":"2026-07-13T13:41:00Z"}
```

This file-based bridge is easier to debug than an HTTP service and avoids requiring a local network listener in the first version. A local HTTP endpoint can be added later if hooks strongly prefer it.

## Claude/Codex Integration

The MVP should support hook-first integration.

For Claude Code:

- Provide a small command or script that appends JSONL events to the Greenlight bridge file.
- Document which Claude Code hook events map to Greenlight states.

For Codex:

- Start with manual/demo events if Codex hook support is not available in the local environment.
- Add a hook/command integration once the supported extension point is confirmed.

The UI should not depend on both integrations being complete. The app can be useful with simulated/manual events while the integrations mature.

## Demo Mode

The mockup's bottom dock is useful for testing and pitching, but should not appear in normal use.

Demo mode should provide:

- Play loop: running -> needs input -> escalated -> jump back -> running.
- Simulate needs input.
- Simulate blocked.
- Simulate done.
- Clear/reset.

This can live in a preferences toggle, debug menu, or separate demo window/popover section.

## Visual Design

The app should follow the mockup closely:

- Native Mac menu bar presence.
- Translucent popover material.
- Compact row spacing.
- Rounded but not oversized controls.
- Calm color system: green, yellow, red, blue, gray.
- Optional playful traffic-light mascot.

The mascot should be treated as optional personality, not required comprehension. The colored status dot and session labels must communicate state on their own.

## Error Handling

The app should handle:

- Missing bridge file by creating it automatically.
- Invalid JSONL events by ignoring the bad line and recording a lightweight diagnostic.
- Unknown tool names by showing them as "Agent."
- Unknown state values by mapping to `idle` or `unknown`.
- Missing jump targets by disabling or hiding the jump action for that row.

If the app cannot monitor the event file, it should show a gray status and an explanation in the popover footer or preferences.

## Testing Strategy

The first build should include:

- Unit tests for aggregate status rules.
- Unit tests for JSONL event parsing.
- Unit tests for stale/escalated session detection.
- Manual UI verification for menu bar item, popover, onboarding, preferences, and demo mode.

If the project setup makes UI tests too heavy initially, keep UI verification manual but make the state engine and parser testable from the start.

## Milestone Plan

### Milestone 1: Native Shell

- Create Swift/SwiftUI macOS menu bar app.
- Add menu bar item with mock aggregate state.
- Add popover with static session rows.

### Milestone 2: State Engine

- Add session model and store.
- Add aggregate state calculation.
- Add stale/escalation timer.
- Wire popover to live state.

### Milestone 3: Onboarding and Preferences

- Add onboarding flow.
- Add preferences for count, playful mode, escalation time, and demo mode.

### Milestone 4: Event Bridge

- Add app support bridge file.
- Watch and parse JSONL events.
- Update sessions from events.
- Add sample hook command/script.

### Milestone 5: Demo and Polish

- Add demo loop controls behind demo mode.
- Tune visual details against the HTML mockup.
- Add tests for parser and state rules.

## Open Questions

- Should the first build support both list and card layouts, or should cards wait?
- Should "done" appear blue briefly and then clear automatically?
- What should the default escalation delay be: 5, 10, or 15 minutes?
- Should the jump action open a folder, focus a terminal window, or run a command first?
- Should onboarding install hooks automatically or only show commands to run manually?

## Approval Check

This design assumes the first implementation should prioritize a native, useful menu bar app over broad integrations. It also assumes the HTML mockup is the visual reference, with the demo dock moved into explicit demo mode.
