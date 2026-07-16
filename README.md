# Project Greenlight

Project Greenlight is a macOS menu bar companion for AI coding agents. It shows whether Claude, Codex, or another agent is running, waiting for input, done, or blocked, so background work does not disappear from your attention.

## Current MVP

- Native Swift/SwiftUI menu bar app
- Colored status indicator with optional waiting count
- Compact popover with session rows and status pills
- Playful traffic-light mascot with face and subtle motion
- Preferences for count display, mascot, escalation timing, and demo mode
- JSONL event bridge for hook-based integrations
- Local Claude Code and Codex connection installer with config backups
- Swift tests for status aggregation, event parsing, bridge polling, and escalation

## Run Locally

```bash
swift run --disable-sandbox --cache-path .build/swiftpm-cache GreenlightApp
```

## Run Tests

```bash
swift test --disable-sandbox --cache-path .build/swiftpm-cache
```

## Package as a macOS App

```bash
scripts/package-app.sh
```

The packaged app is written to `outputs/Greenlight.app`, with a zipped copy at `outputs/Greenlight-0.1.0.zip`. These generated artifacts are ignored by git.

The bundle includes a generated Greenlight app icon and is ad-hoc signed for local testing. For a public release, use Developer ID signing and notarization.

## Event Bridge

Greenlight watches:

```text
~/Library/Application Support/Greenlight/events.jsonl
```

Hooks can append JSON lines like:

```json
{"id":"project-greenlight","tool":"claude","project":"project-greenlight","state":"needsInput","timestamp":"2026-07-13T13:41:00Z","jumpTarget":"/Users/justin.li/work/project-greenlight"}
```

Supported states:

- `running`
- `needsInput`
- `blocked`
- `done`
- `idle`

Supported tools:

- `claude`
- `codex`
- `other`

## Claude and Codex Connections

Greenlight can connect to Claude Code and Codex from onboarding or Preferences.

The installer is local and reversible:

- Claude Code: Greenlight updates `~/.claude/settings.json` with hook commands for `SessionStart`, `Notification`, `Stop`, and `StopFailure`.
- Codex: Greenlight updates `~/.codex/config.toml` with a `notify` wrapper. If a notify command already exists, the wrapper calls it first, then sends Greenlight an update.
- Backups: Greenlight copies each config file before editing it and writes helper scripts to `~/Library/Application Support/Greenlight/`.
- Test signal: onboarding and Preferences include a button that appends a real test event to the bridge so the menu bar light changes immediately.

Demo mode is turned off after a successful connection or test signal so real events become the main source of status.

## Release Notes

This is an unsigned/ad-hoc signed local MVP. A public release should use Developer ID signing and notarization.
