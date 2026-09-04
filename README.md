# PeekBar

> **Seamless edge-triggered reveal of the Omarchy bar over fullscreen applications without disturbing window state, geometry, or keyboard focus.**

PeekBar is a full `kind: bar` replacement plugin for the [Omarchy](https://github.com/omarchy/omarchy) desktop environment on Hyprland. When an application enters fullscreen, PeekBar slides out of view to give you an uncompromised full-screen canvas while leaving a minimal, invisible edge trigger. Moving your pointer to the monitor's top edge smoothly reveals PeekBar directly over the fullscreen window — allowing full interaction with all your widgets, workspace icons, and system panels.

[![Omarchy Plugin](https://img.shields.io/badge/omarchy-plugin-blue.svg)](https://omarchyplugins.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Kind: bar](https://img.shields.io/badge/kind-bar-green.svg)](#)
[![Platform: Wayland / Hyprland](https://img.shields.io/badge/platform-Wayland%20%7C%20Hyprland-purple.svg)](#)

---

## The Experience


https://github.com/user-attachments/assets/d7b2146b-8143-4c5e-befc-6f07d7689a36


When your pointer leaves the bar and any active popup, PeekBar smoothly slides out of view after a debounced delay (default `300 ms`).

---

## Key Features

- **True Wayland Layer-Shell Overlay**: Uses `WlrLayer.Overlay` with `exclusionMode: ExclusionMode.Ignore` when revealed in fullscreen. Never displaces, shifts, or resizes the fullscreen surface.
- **Zero Disturbance**: PeekBar **never** calls `hyprctl dispatch fullscreen` or manipulates client state. The application remains natively fullscreen at all times.
- **No Focus Stealing**: All PeekBar surfaces explicitly enforce `WlrLayershell.keyboardFocus: WlrKeyboardFocus.None`. The active application retains keyboard focus without interruption.
- **Universal Widget & Popup Support**: Seamlessly interacts with all Omarchy widgets, including audio, network, bluetooth, power, calendar, media, tray popups, and third-party panels. The bar stays visible while you interact with popouts and only hides once popups close and the pointer departs.
- **Per-Monitor State Machine**: Fullscreen state is evaluated per-monitor. If you have a fullscreen video on Monitor 1 and code editor on Monitor 2, Monitor 2 retains its standard pinned bar.
- **Flicker-Free Edge Handoff**: The transparent 2px trigger surface remains mapped during fullscreen, guaranteeing seamless pointer handoff to the bar surface with zero hover gaps.
- **Smooth Animated Transitions**: Configurable slide animation with cubic easing and debounce timers to eliminate accidental reveal/hide loops.
- **100% Stock Compatibility**: Preserves all stock Omarchy bar functionality: theme colors, transparent mode, font configuration, slot layout, drag-and-drop widget arrangement, and notifications.

---

## Installation

### Via Omarchy Plugin Manager (omarchyplugins.com)

```bash
omarchy plugin add https://github.com/sanjyay/peekbar.git --enable
```

### Manual / Git Clone

Clone or link the repository into your Omarchy plugins directory:

```bash
git clone https://github.com/sanjyay/peekbar.git ~/.config/omarchy/plugins/peekbar
```

---

## Configuration

PeekBar accepts the following configuration keys under the `"bar"` object in `~/.config/omarchy/shell.json`:

| Option | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `id` | `string` | `"peekbar"` | Plugin ID to activate PeekBar as the active bar. |
| `revealInFullscreen` | `boolean` | `true` | When `true`, enables edge-triggered peek reveal in fullscreen. When `false`, acts like the stock Omarchy bar. |
| `triggerThickness` | `integer` | `2` | Height of the invisible top-edge hover trigger strip in logical pixels (range: `1`–`20`). |
| `revealDelay` | `integer` | `0` | Delay in milliseconds before revealing the bar after pointer enters the edge (useful to prevent accidental triggers). |
| `hideDelay` | `integer` | `300` | Delay in milliseconds before hiding the bar after pointer leaves both the bar and open popups. |
| `animationDuration` | `integer` | `150` | Slide animation duration in milliseconds (`0` for instantaneous). |

---

## Uninstallation / Reverting

To remove the plugin completely:

```bash
omarchy plugin remove peekbar
omarchy-restart-shell
```

---

## State Model

```text
       NORMAL
         │
         │ Fullscreen window active on monitor
         ▼
  FULLSCREEN_HIDDEN
         │
         │ Pointer enters top-edge trigger
         ▼
 FULLSCREEN_REVEALED
         │
         │ Pointer leaves bar & popups closed
         │ hideDelay timer expires
         ▼
  FULLSCREEN_HIDDEN
         │
         │ Fullscreen ends on monitor
         ▼
       NORMAL
```

---

## Architecture

- [`manifest.json`](manifest.json): Plugin contract definition declaring PeekBar as an Omarchy `kind: bar` plugin.
- [`Bar.qml`](Bar.qml): Root bar component adapted from stock Omarchy Quattro bar, integrating per-screen scopes, universal popup lifecycle tracking, and smooth margin animations.
- [`PeekBarController.qml`](PeekBarController.qml): Per-monitor state machine. Watches Hyprland workspace fullscreen states, tracks trigger and bar hover states, and manages debounced reveal/hide timers.
- [`TriggerPanel.qml`](TriggerPanel.qml): Dedicated 2px edge `PanelWindow` on `WlrLayer.Overlay` with `ExclusionMode.Ignore` and `WlrKeyboardFocus.None` that catches top-edge pointer hover without intercepting clicks.
- [`BarModel.js`](BarModel.js): Upstream layout normalization and tray alignment utilities.

---

## Security & Privacy Audit

Omarchy plugins share the long-running shell process and execute unsandboxed with user privileges. PeekBar has undergone a comprehensive security audit to guarantee safe operation:

1. **No External Process Execution**: PeekBar introduces **no** new subprocess calls, shell invocations, `curl`, `wget`, or background daemons. The only process probes present are inherited directly from upstream stock Omarchy for bar-off toggle tracking.
2. **No Window State Manipulation**: PeekBar **never** alters client window states (no `hyprctl dispatch fullscreen` or similar commands). Fullscreen overlay is achieved purely through standard Wayland layer-shell protocol semantics.
3. **No Keyboard Interception**: All surfaces declare `WlrLayershell.keyboardFocus: WlrKeyboardFocus.None`. PeekBar cannot capture keystrokes, intercept credentials, or steal input from the active application.
4. **No Network Activity**: PeekBar makes zero network requests, uses no sockets, and transmits zero telemetry.
5. **No File System Modifications**: PeekBar reads configuration exclusively through the host-injected `barConfig` and makes no modifications to user configurations, system directories, or `/usr/share/omarchy/`.
6. **Resource Efficiency**: Event-driven architecture hooked to compositor signals (`Quickshell.Hyprland`). Zero polling loops, zero busy-wait timers, and effectively 0% idle CPU utilization.

---

## Verification & Testing

Verify manifest and QML integrity:

```bash
# Validate plugin manifest against Omarchy schema
omarchy plugin validate .

# Lint QML components
qmllint -I /usr/share/omarchy/shell PeekBarController.qml TriggerPanel.qml
```

---

## License

This project is licensed under the [MIT License](LICENSE). Portions adapted from upstream [Omarchy](https://github.com/omarchy/omarchy).
