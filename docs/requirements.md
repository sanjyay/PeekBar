# Requirements & Invariants — PeekBar

This document specifies the non-negotiable architectural invariants, functional requirements, and marketplace standards that govern PeekBar.

---

## 1. Core Architectural Invariants

Every agent or contributor modifying PeekBar must uphold the following core principles:

1. **PeekBar overlays fullscreen; it never breaks fullscreen.**
   * PeekBar must **never** execute `hyprctl dispatch fullscreen`, toggle client window states, or alter compositor fullscreen flags.
   * Fullscreen reveal is achieved exclusively through Wayland layer-shell protocol semantics (`WlrLayer.Overlay`).

2. **Zero Keyboard Focus Stealing.**
   * All bar and trigger surfaces must set `WlrLayershell.keyboardFocus: WlrKeyboardFocus.None`.
   * The active fullscreen application must retain keyboard focus undisturbed while the bar reveals, slides, or hides.

3. **Zero Window Geometry Disturbance.**
   * In fullscreen mode, the bar surface and trigger surface must set `exclusionMode: ExclusionMode.Ignore`.
   * Fullscreen windows must never resize, shake, or jitter when the bar appears or disappears.

4. **Multi-Monitor Isolation.**
   * Fullscreen state is scoped per monitor (`Hyprland.monitorFor(screen)`).
   * A fullscreen window on Monitor 1 must not affect the visibility or exclusive zone of the bar on Monitor 2.

5. **Universal Widget & Popup Continuity.**
   * The bar must remain visible whenever any widget popup or menu is open (`activePopout != null`).
   * Hiding must wait until the popup is dismissed AND the pointer has exited the bar area.

---

## 2. Functional Requirements

### 2.1 State Model
PeekBar must implement an explicit 3-state machine per monitor:
* **`STATE_NORMAL` (0)**: Normal workspace state. Bar mapped at `WlrLayer.Top`, `ExclusionMode.Auto`.
* **`STATE_FULLSCREEN_HIDDEN` (1)**: Fullscreen active on workspace, pointer outside edge trigger. Bar parked at `-barSize`, `WlrLayer.Overlay`, `ExclusionMode.Ignore`. 2px trigger mapped at top edge.
* **`STATE_FULLSCREEN_REVEALED` (2)**: Fullscreen active, pointer inside trigger, bar, or interacting with popup. Bar visible at margin `0`, `WlrLayer.Overlay`.

### 2.2 Trigger Surface
* Positioned along the monitor edge matching the bar configuration (`top`, `bottom`, `left`, `right`).
* Thickness configurable via `triggerThickness` (default `2px`, range `1`–`20px`).
* Must remain mapped throughout fullscreen to eliminate hover gaps during slide animations.
* Completely transparent (`color: "transparent"`, `surfaceFormat.opaque: false`).

### 2.3 Debounced Timers
* **`revealDelay`**: Optional delay before reveal starts (default `0ms`).
* **`hideDelay`**: Debounced delay after pointer departs before bar hides (default `300ms`).
* Timers must be cleanly stopped/restarted upon pointer transition events to prevent race conditions.

---

## 3. omarchyplugins.com & Marketplace Requirements

To remain fully compliant with the `omarchyplugins.com` v1 specification:

* **Manifest Schema**: `manifest.json` must have `schemaVersion: 1` as a JSON number.
* **Plugin ID**: Must use a safe identifier (`peekbar`), avoiding reserved prefixes (`omarchy.*`).
* **Entry Point**: Must specify `"kinds": ["bar"]` and `"entryPoints": { "bar": "Bar.qml" }`.
* **No Symlinks**: Plugin folder must contain zero symlinks (enforced by `omarchy-plugin-validate`).
* **Safe Paths**: All imports and entry points must be safe relative paths within the plugin tree.
* **Clean Removal**: Removing the plugin via `omarchy plugin remove peekbar` must allow seamless fallback to `omarchy.bar`.

---

## 4. Security & Privacy Requirements

Omarchy plugins execute unsandboxed within the user's graphical session. The following rules are mandatory:

* **No Subprocesses**: Never invoke `curl`, `wget`, `bash -c`, or arbitrary executables. (Upstream `omarchy.custom` and `bar-off` probes are the only permitted exceptions).
* **No Network Operations**: Zero outbound sockets, telemetry, or network API calls.
* **No Arbitrary Code Evaluation**: Strict ban on `eval()`, `new Function()`, and runtime script loading.
* **No State Tampering**: Read configuration strictly from host-injected `barConfig`. Do not write to arbitrary filesystem locations.
