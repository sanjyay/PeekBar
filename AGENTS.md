# AGENTS.md — PeekBar

## Project Overview

**PeekBar** is an Omarchy/Quickshell bar plugin that adds edge-triggered bar reveal while an application is fullscreen.

The core experience:

1. User enters true fullscreen in Hyprland.
2. The application remains fullscreen.
3. The bar stays hidden.
4. Moving the pointer to the top edge of the monitor reveals PeekBar above the fullscreen window.
5. Moving the pointer away hides the bar again after a short delay.
6. The fullscreen application's state must never be changed by PeekBar.

PeekBar should preserve the appearance and normal behavior of the stock Omarchy bar as closely as possible while adding fullscreen reveal behavior.

---

# Primary Goal

Implement this interaction:

```text
NORMAL
┌─────────────────────────────────┐
│            PeekBar              │
├─────────────────────────────────┤
│                                 │
│           application           │
│                                 │
└─────────────────────────────────┘
```

When the application becomes fullscreen:

```text
FULLSCREEN
┌─────────────────────────────────┐ ← invisible top-edge trigger
│                                 │
│                                 │
│       fullscreen application    │
│                                 │
│                                 │
└─────────────────────────────────┘
```

When the pointer reaches the top edge:

```text
FULLSCREEN + HOVER
┌─────────────────────────────────┐
│            PeekBar              │
├─────────────────────────────────┤
│                                 │
│       fullscreen application    │
│                                 │
└─────────────────────────────────┘
```

The fullscreen application must remain fullscreen throughout this entire interaction.

---

# Non-Negotiable Requirements

## Never toggle application fullscreen

PeekBar must NEVER solve the problem by executing commands such as:

```bash
hyprctl dispatch fullscreen
```

or by otherwise changing the fullscreen state of the active window.

Do not fake the feature by temporarily leaving fullscreen.

The bar must overlay the fullscreen surface.

---

## Do not modify Omarchy system files

Do not directly edit files under locations such as:

```text
/usr/share/omarchy/
```

or other Omarchy-managed system directories.

PeekBar must live entirely as its own plugin/repository.

Development files should remain inside the PeekBar project or the user's Omarchy plugin directory.

---

## Preserve stock Omarchy behavior

Outside fullscreen mode, PeekBar should behave as closely as possible to the standard Omarchy bar.

Do not unnecessarily redesign:

* widgets
* spacing
* typography
* colors
* system indicators
* workspace behavior
* tray behavior
* clock behavior
* bar layout

PeekBar's defining feature is fullscreen reveal.

Avoid unrelated visual or architectural changes.

---

# Architecture

PeekBar is a full Omarchy:

```text
kind: bar
```

plugin.

It is not merely a `bar-widget`.

The bar plugin needs control over:

* the bar window
* visibility
* Wayland layer
* exclusive zone
* fullscreen detection
* pointer interaction
* reveal state
* hide timing
* animation

---

# Expected State Model

Keep the state machine explicit and simple.

Recommended logical states:

```text
NORMAL
FULLSCREEN_HIDDEN
FULLSCREEN_REVEALED
```

Transitions:

```text
NORMAL
  │
  │ fullscreen detected
  ▼
FULLSCREEN_HIDDEN
  │
  │ pointer enters top-edge trigger
  ▼
FULLSCREEN_REVEALED
  │
  │ pointer leaves bar
  │ hide delay expires
  ▼
FULLSCREEN_HIDDEN
  │
  │ fullscreen ends
  ▼
NORMAL
```

Avoid spreading state across many unrelated booleans when one clear state model can be used.

---

# Normal Mode

When no relevant fullscreen window exists on a monitor:

* bar behaves normally
* normal Omarchy positioning is preserved
* normal exclusive zone behavior is preserved
* no invisible hover trigger should interfere with applications
* no unnecessary overlay surface should capture pointer input

---

# Fullscreen Mode

When a fullscreen application is present:

* main bar should be hidden
* a very small top-edge trigger should remain
* trigger should normally be approximately 1–2 logical pixels tall
* trigger should only capture the area necessary to detect the edge hover
* fullscreen application must continue covering the monitor
* PeekBar must not reserve normal bar space

The bar should effectively use:

```text
exclusive zone = 0
```

while acting as a fullscreen overlay.

---

# Revealed Mode

When the pointer reaches the top edge:

* reveal the bar
* place it above the fullscreen application
* use the appropriate Wayland overlay layer
* do not resize the fullscreen application
* do not move the fullscreen application
* do not change workspace
* do not alter fullscreen state
* do not steal keyboard focus

The user should be able to interact with bar widgets normally while it is revealed.

---

# Hide Behavior

When the pointer leaves both:

* the visible bar
* any region that logically counts as part of the reveal interaction

start a hide timer.

Recommended initial value:

```text
300 ms
```

If the pointer returns before the timer expires:

* cancel the pending hide

This prevents flickering and accidental disappearance.

---

# Initial Configuration

Target configuration options:

```json
{
  "revealInFullscreen": true,
  "triggerThickness": 2,
  "revealDelay": 0,
  "hideDelay": 300,
  "animationDuration": 150
}
```

Possible future options:

```json
{
  "animation": "slide",
  "position": "top",
  "requirePointerLeave": true
}
```

Do not over-engineer configuration during the first implementation.

First make the core behavior reliable.

---

# Implementation Priority

Implement features in this order.

## Phase 1 — Functional Prototype

Get only this working:

1. Detect fullscreen state.
2. Hide bar in fullscreen.
3. Keep a top-edge trigger.
4. Pointer reaches top edge.
5. Bar appears over fullscreen application.
6. Application remains fullscreen.
7. Pointer leaves bar.
8. Bar disappears.

No animation is required at this stage.

---

## Phase 2 — Reliability

After the basic interaction works:

* remove flicker
* prevent accidental repeated reveal/hide loops
* ensure pointer events behave correctly
* ensure no focus stealing
* ensure exclusive-zone changes do not move windows
* handle fullscreen transitions cleanly
* handle application exit while bar is revealed

---

## Phase 3 — Multi-Monitor

Fullscreen state must be evaluated per monitor wherever possible.

Expected behavior:

```text
Monitor 1
fullscreen app
→ PeekBar hides
→ edge hover reveals PeekBar

Monitor 2
normal tiled windows
→ PeekBar remains normally visible
```

Do not globally hide every monitor's bar merely because one monitor contains a fullscreen application unless the underlying Omarchy API makes per-monitor behavior impossible.

If an API limitation prevents correct per-monitor behavior, document it clearly rather than hiding it with fragile hacks.

---

## Phase 4 — UX

Only after reliability:

* slide animation
* configurable delays
* configurable trigger thickness
* configuration validation
* polished transitions

Animations must not compromise pointer reliability.

Functionality is more important than animation.

---

## Phase 5 — Packaging

Prepare for Omarchy plugin distribution:

* clean manifest
* README
* screenshots or demonstration GIF if appropriate
* installation instructions
* configuration documentation
* license
* repository metadata
* validation

---

# Wayland / Quickshell Rules

This is a Wayland/Hyprland/Quickshell project.

Do not introduce X11-specific workarounds.

The revealed bar needs to appear above a fullscreen client using the appropriate layer-shell behavior.

Conceptually:

```text
Normal:
    layer = Top

Fullscreen reveal:
    layer = Overlay
    exclusive zone = 0
```

Exact APIs must follow the version of Quickshell used by Omarchy.

Do not blindly assume API names.

Inspect the existing Omarchy bar implementation and current Quickshell types before modifying code.

---

# Edge Trigger

The edge trigger should:

* exist only when useful
* be almost invisible in terms of geometry
* not visibly alter the screen
* not reserve workspace space
* not cause fullscreen applications to resize
* avoid intercepting clicks unnecessarily

Recommended starting geometry:

```text
x      = monitor left
y      = monitor top
width  = monitor width
height = 2
```

Its purpose is pointer detection only.

---

# Pointer Interaction

Be careful around the transition between:

```text
edge trigger → revealed bar
```

A common failure mode is:

1. pointer enters trigger
2. trigger reveals bar
3. trigger surface disappears
4. pointer temporarily counts as outside everything
5. hide logic fires
6. bar flickers

Design the interaction to prevent this.

Potential strategies include:

* keeping trigger active behind the bar
* considering both trigger and bar hover state
* delaying hide
* using one shared reveal controller

Avoid timers fighting each other.

---

# Fullscreen Detection

Use information already exposed by Omarchy/Quickshell/Hyprland whenever possible.

Prefer event-driven state.

Avoid continuously spawning commands such as:

```bash
hyprctl clients
```

on short polling intervals.

Do not create expensive shell-command polling loops when live Hyprland state is already available through the shell environment.

If polling is absolutely necessary, document why.

---

# Performance

PeekBar runs continuously as part of the user's desktop shell.

Therefore:

* avoid unnecessary subprocesses
* avoid frequent polling
* avoid busy timers
* avoid unnecessary object creation
* avoid repeated filesystem reads
* avoid blocking operations
* avoid excessive logging during normal use

Idle CPU usage attributable to PeekBar should be effectively negligible.

---

# Error Handling

PeekBar must fail gracefully.

If fullscreen detection is unavailable:

* normal bar behavior should continue

If configuration is malformed:

* use safe defaults where reasonable
* log a useful error
* do not crash the entire Omarchy shell

If animation fails:

* prefer immediate reveal/hide over a broken bar

---

# Logging

Logs should be useful for debugging without being noisy.

Good examples:

```text
PeekBar: fullscreen entered on HDMI-A-1
PeekBar: fullscreen reveal activated
PeekBar: invalid hideDelay value, using 300
```

Do not continuously print messages for pointer movement.

Debug-only logging should be easy to disable.

---

# Coding Style

Prefer:

* small components
* clear property names
* explicit state
* minimal nesting
* reusable logic
* comments explaining non-obvious Wayland behavior

Avoid:

* giant monolithic QML files
* duplicated fullscreen logic
* magic numbers spread throughout the code
* shell commands embedded throughout UI components
* premature abstractions

If a value such as `300` or `2` has semantic meaning, expose it as a named property.

---

# Comments

Comments should explain WHY something exists, especially around:

* Wayland layer-shell behavior
* exclusive zones
* pointer transition handling
* fullscreen detection
* multi-monitor edge cases

Do not add comments that simply repeat the code.

Bad:

```qml
// Set visible to true
visible: true
```

Good:

```qml
// Keep the trigger mapped while fullscreen so pointer entry can
// reveal the overlay bar without changing the client's fullscreen state.
```

---

# Repository Hygiene

Never commit:

* API tokens
* personal paths
* machine-specific secrets
* generated caches
* editor temporary files
* debug dumps
* unrelated Omarchy configuration

Keep the repository portable.

---

# Git Workflow

Use focused commits.

Examples:

```text
feat: add fullscreen state detection
feat: add top-edge reveal trigger
fix: prevent bar flicker during trigger transition
feat: support per-monitor fullscreen reveal
feat: add reveal and hide animations
docs: document PeekBar configuration
```

Avoid one enormous commit containing the entire project unless this is the initial import.

---

# Scope Discipline

Do not introduce unrelated features while implementing PeekBar.

Examples of out-of-scope work:

* redesigning Omarchy's workspace widget
* creating a new notification system
* changing system tray behavior
* replacing Hyprland keybindings
* adding unrelated themes
* rewriting working Omarchy widgets
* changing application fullscreen mechanics

Record unrelated improvements as possible future work instead.

---

# Compatibility

PeekBar should target the current Omarchy shell architecture.

When copying or adapting stock Omarchy bar code:

* preserve attribution/license requirements
* document the upstream source
* minimize divergence
* avoid unnecessary modifications

Where practical, isolate PeekBar-specific behavior so upstream Omarchy bar updates can be incorporated later with minimal conflict.

---

# Testing Requirements

Every meaningful implementation must be tested manually in a live Hyprland session.

Minimum test matrix:

## Normal windows

* tiled window
* floating window
* maximized window if applicable
* changing workspace
* switching focused applications

Expected:

```text
normal bar behavior unchanged
```

---

## Fullscreen

Test at least:

* browser fullscreen
* terminal fullscreen
* native Wayland application fullscreen
* fullscreen entered using Hyprland
* fullscreen exited using Hyprland

Expected:

```text
bar hidden
top edge reveals bar
application remains fullscreen
leaving bar hides it
```

---

## Pointer tests

Test:

* slow pointer movement to top
* fast flick to top edge
* moving horizontally across revealed bar
* moving from trigger directly into widget
* leaving downward into application
* rapidly entering/leaving repeatedly

There must be no persistent flicker loop.

---

## Interaction tests

While bar is revealed:

* click workspace widget
* click system tray item
* interact with clock if applicable
* use any popups provided by stock widgets

The bar must remain functionally usable.

---

## Multi-monitor tests

Where hardware/setup permits:

* fullscreen on monitor A only
* fullscreen on monitor B only
* fullscreen windows on both
* move pointer between monitors
* workspace changes independently

A monitor without fullscreen content should not unnecessarily lose its normal bar.

---

## Shell reload

Test:

```bash
omarchy-shell restart
```

or the appropriate current Omarchy shell reload mechanism.

Also test plugin hot reload when available.

PeekBar must recover cleanly without requiring logout.

---

# Regression Checklist

Before considering a change complete, verify:

```text
[ ] Normal Omarchy bar still works
[ ] Fullscreen application stays fullscreen
[ ] Bar overlays fullscreen content
[ ] No window resizing during reveal
[ ] No workspace movement
[ ] No keyboard-focus stealing
[ ] Trigger does not create visible artifacts
[ ] No hover flicker
[ ] Hide timer cancels correctly
[ ] Bar widgets remain clickable
[ ] Shell does not crash
[ ] No excessive CPU usage
[ ] Multi-monitor behavior tested or limitation documented
```

---

# Definition of Done

PeekBar's core feature is complete when:

> A user can fullscreen an application, move the pointer to the top edge, interact with the Omarchy bar displayed over the application, move the pointer away, and have the bar disappear again — without the application ever leaving fullscreen or changing size.

Anything that violates that sentence is a bug.

---

# Agent Instructions

When working on this repository:

1. Inspect existing code before proposing changes.
2. Understand the stock Omarchy bar architecture before replacing components.
3. Search for existing abstractions before creating new ones.
4. Make the smallest reliable change.
5. Test after every meaningful implementation step.
6. When a test fails, determine the root cause rather than layering workarounds.
7. Do not claim an issue is fixed without verifying the relevant behavior.
8. Preserve existing working behavior.
9. Keep PeekBar-specific logic isolated where practical.
10. Document limitations instead of concealing them.
11. Prefer maintainability over cleverness.
12. Never manipulate the fullscreen client's state to implement bar reveal.

When uncertain about Quickshell or Omarchy APIs, inspect the installed/current implementation rather than guessing.

---

# Project Principle

**PeekBar overlays fullscreen. It never breaks fullscreen.**
