# Project Greenlight: Light Product Brief

## One-Line Concept

Project Greenlight is a Mac menu bar companion that shows, at a glance, whether Claude, Codex, or other AI work sessions are running, waiting for input, done, or blocked.

## Problem

AI coding agents are useful because they can work in the background, but that same background nature creates a new failure mode: the user forgets the agent is waiting. Notifications are easy to miss, and switching back into Claude or Codex requires remembering to check.

The result is a subtle but painful productivity leak: the agent finishes, asks for input, or gets blocked, but the user keeps working elsewhere and loses time.

## Target User

The first user is a Mac-based builder who runs Claude Code, Codex, or similar agent tools during the workday and often has more than one work thread open.

This person does not need a full agent dashboard. They need a persistent, low-friction signal that answers: "Does anything need me right now?"

## Product Bet

The best first version is not another big window. It is a menu bar app.

The menu bar is visible, habitual, and lightweight. It can carry a simple status indicator at all times, while a click opens a richer popover for details.

## Core Experience

Greenlight lives in the macOS menu bar as a small status item:

- Green: all active agents are running or clear
- Yellow: at least one agent needs user input
- Red: at least one agent is blocked, failed, or stale
- Gray: no active sessions detected

Clicking the menu bar item opens a compact popover showing each tracked session, including:

- Tool: Claude, Codex, or other
- Project/session name
- Current state
- Time since state changed
- A quick action to jump back to the related app, terminal, or workspace

## MVP Scope

The MVP should focus on reliable status visibility over broad automation.

In scope:

- Mac menu bar indicator
- Popover with active sessions
- Status states: running, needs input, done, blocked, idle/unknown
- Hook-based status updates from supported tools
- Manual session registration as a fallback
- Stale-session detection, such as "waiting for 10+ minutes"
- Basic settings for reminder timing and visual intensity

Out of scope for MVP:

- Full desktop dashboard
- Cross-device sync
- Team/shared agent monitoring
- Deep control of Claude or Codex internals
- Complex notification scraping as the primary detection method

## Detection Strategy

Recommended approach: hybrid, starting hook-first.

Hook-based detection should be the MVP foundation because it is explicit and reliable. Claude/Codex sessions can report status changes to Greenlight through a small local bridge.

Later, Greenlight can add fallback detection:

- macOS notification observation
- app/window/title heuristics
- terminal process detection
- integrations with other agent tools

This keeps the first version buildable while preserving the larger vision.

## Why Now

Agent work is becoming more concurrent and longer-running. A recent Codex usage study reports that more than 10% of users manage three or more concurrent Codex agents at least once per week, which makes "what needs me?" a real workflow problem rather than a novelty.

## Existing Landscape

Nearby solutions exist, but they appear fragmented:

- Native app notifications can tell the user something happened, but they are transient and easy to miss.
- Agent tools may expose their own status surfaces, but those are usually inside the app or terminal.
- Some tools support hooks or extensibility, which can feed Greenlight.
- A dedicated cross-tool Mac menu bar status layer remains a distinct product shape.

Greenlight's differentiator is not "another notification." It is persistent ambient awareness across agent tools.

## Product Personality

Greenlight should feel useful, calm, and a little fun.

It should borrow the instant readability of a traffic light, but avoid becoming noisy. The tone should be closer to a helpful desk signal than an alarm system.

Possible visual directions:

- Minimal menu bar dot or pill
- Small "2 waiting" label when attention is needed
- Optional playful mode with a tiny animated status character
- Popover design that feels compact and practical

## Success Criteria

The first version succeeds if:

- The user notices when Claude or Codex needs them within a minute or two.
- The menu bar status is understandable without opening the popover.
- The popover makes it obvious which session needs attention.
- The tool reduces "I totally forgot this was waiting" moments.
- Setup is simple enough that the user keeps it running every day.

## Open Questions

- Should the menu bar indicator show only color, or color plus text?
- What is the exact default timing before a waiting session escalates?
- Which tool should be integrated first: Claude Code, Codex, or both in parallel?
- Should "done" be treated as green, yellow, or a separate celebratory state?
- Should Greenlight include an optional floating desk widget later?

## Recommended Next Step

Design the MVP around one high-confidence flow:

1. A Claude or Codex session starts.
2. Greenlight shows it as running.
3. The agent completes or requests input.
4. Greenlight turns yellow and shows "Needs input."
5. If ignored for several minutes, Greenlight escalates visually.
6. The user clicks the menu bar item and jumps back to the session.

That loop captures the core value of Project Greenlight.
