# Architecture Specification — PeekBar

This document outlines the technical architecture, component breakdown, Wayland layer-shell interactions, and event flow for PeekBar.

---

## 1. System Architecture Overview

PeekBar replaces the stock Omarchy status bar by implementing the `kind: bar` plugin interface. Rather than re-implementing widgets and layout from scratch, it adapts the upstream Omarchy Quattro bar architecture, wrapping each monitor's instance in an isolated controller with an edge-detection trigger.

```text
┌────────────────────────────────────────────────────────────────────────┐
│                               Bar.qml                                  │
│  - Plugin Entry Point (kind: bar)                                      │
│  - Host Injections (omarchyPath, barWidgetRegistry, barConfig)          │
│  - Global Popout Lifecycle Coordinator (requestPopout / releasePopout) │
│                                                                        │
│   Variants (model: Quickshell.screens)                                 │
│   └── Scope (per monitor)                                              │
│       ├── PeekBarController.qml  (Fullscreen & hover state machine)   │
│       ├── TriggerPanel.qml       (2px invisible edge overlay surface)  │
│       └── BarPanel               (Primary bar surface on layer-shell)  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Component Specifications

### 2.1 `Bar.qml` (Root Entry Point)
* **Role**: Root component injected into the running Omarchy shell.
* **Injections from Host**:
  * `barConfig`: Host settings from `~/.config/omarchy/shell.json`.
  * `barWidgetRegistry`: Map of discovered widgets and their QML components.
  * `shell`: IPC bridge for shell settings and notifications.
* **Popup Coordinator**:
  * Manages active popouts via `requestPopout(owner)` and `releasePopout(owner)`.
  * Broadcasts `popupHovered` state to all per-screen controllers, preventing auto-hide while popups are open.

### 2.2 `PeekBarController.qml` (State Machine)
* **Role**: Isolated per-monitor state coordinator (`QtObject`).
* **Compositor Bindings**:
  * `hyprMonitor: Hyprland.monitorFor(screen)`
  * `activeWs: hyprMonitor.activeWorkspace`
  * `isFullscreen: revealInFullscreen && activeWs.hasFullscreen`
* **Hover State Resolution**:
  * `pointerActive = triggerHovered || barSurfaceHovered || popupHovered`
* **Timers**:
  * `revealTimer`: Configurable delay before showing bar (default 0ms).
  * `hideTimer`: Debounced countdown (default 300ms) before hiding after pointer departure.

### 2.3 `TriggerPanel.qml` (Edge Detection Surface)
* **Role**: 2px layer-shell surface that catches pointer hover at the monitor edge.
* **Layer-Shell Attributes**:
  * `WlrLayershell.namespace: "omarchy-peekbar-trigger"`
  * `WlrLayershell.layer: WlrLayer.Overlay`
  * `WlrLayershell.keyboardFocus: WlrKeyboardFocus.None`
  * `exclusionMode: ExclusionMode.Ignore`
* **Mapping Strategy**:
  * Kept mapped throughout fullscreen (`visible: controller.isFullscreen`).
  * Sitting directly above the fullscreen window, it captures entry at `y = 0..1` and hands off hover to the bar as it slides into view.

### 2.4 `BarPanel` (Primary Bar Surface)
* **Role**: Primary UI rendering the widget layout.
* **Surface Parking**:
  * In fullscreen mode, instead of unmapping (which destroys the Wayland surface and scene graph), the bar is parked off-screen (`targetMarginTop: -barSize`).
  * Reveal is an instantaneous animated margin change (`Behavior on activeMarginTop`).

---

## 3. Wayland Layer-Shell Protocol Mechanics

| Mode | Target Layer | Exclusion Mode | Target Margin | Keyboard Focus |
| :--- | :--- | :--- | :--- | :--- |
| **Normal** | `WlrLayer.Top` | `ExclusionMode.Auto` | `0` | `WlrKeyboardFocus.None` |
| **Fullscreen (Hidden)** | `WlrLayer.Overlay` | `ExclusionMode.Ignore` | `-barSize` | `WlrKeyboardFocus.None` |
| **Fullscreen (Revealed)** | `WlrLayer.Overlay` | `ExclusionMode.Ignore` | `0` | `WlrKeyboardFocus.None` |

---

## 4. Universal Popup Lifecycle Flow

```text
User clicks Widget
       │
       ▼
widget.requestPopout(owner)
       │
       ▼
Bar.qml sets activePopout = owner
       │
       ▼
setControllersPopupHovered(true)
       │
       ▼
PeekBarController.pointerActive = true  ──► hideTimer.stop()
                                            (Bar stays revealed)
       │
User dismisses popup
       │
       ▼
widget.releasePopout(owner)
       │
       ▼
setControllersPopupHovered(false)
       │
       ▼
hideTimer.restart() ──────────────────────► Bar slides off-screen after 300ms
```
