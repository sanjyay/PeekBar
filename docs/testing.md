# Testing & Quality Assurance — PeekBar

This document defines the test matrices, verification procedures, and regression checklists required for any changes to PeekBar.

---

## 1. Automated Verification Suite

Run these checks prior to every commit:

```bash
# 1. Validate Omarchy plugin manifest contract
omarchy plugin validate .

# 2. Lint QML components against Omarchy shell scope
qmllint -I /usr/share/omarchy/shell PeekBarController.qml TriggerPanel.qml

# 3. Verify JavaScript syntax for layout helpers
node -c BarModel.js

# 4. Check for forbidden symlinks in the plugin tree
find . -name .git -prune -o -type l -print

# 5. Check git formatting and whitespace errors
git diff --check
```

---

## 2. Live Session Manual Test Matrix

Because PeekBar operates across Wayland layer-shell boundaries and Hyprland compositor events, all functional changes must be tested in a live graphical session.

### Test 1: Normal Window Behavior (Non-Fullscreen)
* **Setup**: Open tiled and floating windows across workspaces.
* **Actions**:
  1. Move mouse across the bar.
  2. Switch workspaces and focus between windows.
  3. Verify bar visibility and layout.
* **Expected Outcome**:
  * Bar remains pinned in `WlrLayer.Top` with `ExclusionMode.Auto`.
  * Normal Omarchy bar geometry, widgets, and exclusive zones are preserved.
  * No transparent hover triggers interfere with client windows.

### Test 2: Fullscreen Entry & Concealment
* **Setup**: Launch applications capable of true fullscreen:
  * Chromium / Firefox / Brave (`F11` or YouTube fullscreen video).
  * Video player (`mpv --fullscreen`).
  * Terminal emulator (fullscreen toggle).
* **Actions**:
  1. Enter fullscreen on Monitor 1.
* **Expected Outcome**:
  * Bar smoothly parks off-screen (`targetMarginTop = -barSize`).
  * Application occupies 100% of the display canvas without letterboxing.
  * Exclusive zone drops to `0` (`ExclusionMode.Ignore`).
  * 2px invisible trigger surface maps at `WlrLayer.Overlay` along the top edge.

### Test 3: Edge Hover Reveal & Pointer Navigation
* **Actions**:
  1. Move pointer to `y = 0` (top edge).
  2. Move pointer slowly from `y = 0` downwards into the revealed bar.
  3. Move pointer rapidly across widget boundaries.
  4. Perform high-velocity "flicks" to the top edge and back.
* **Expected Outcome**:
  * Bar slides smoothly into view (`activeMarginTop` animates to `0`).
  * Seamless handoff between the 2px trigger and the 35px bar surface.
  * Zero flicker loops, oscillation, or visual tearing.

### Test 4: Universal Widget Interaction & Popup Persistence
* **Actions**:
  1. While revealed in fullscreen, click a `PopupCard` widget (e.g. system tray, menu).
  2. Click a `KeyboardPanel` widget (e.g. audio, network, bluetooth, power).
  3. Move cursor inside the popup card/window away from the top bar strip.
  4. Perform actions inside the popup (adjust volume, toggle Wi-Fi, etc.).
* **Expected Outcome**:
  * Bar remains fully visible for the entire duration the popup is active.
  * Bar does **not** hide when cursor moves down into the popup content.
  * Keystrokes inside popup (e.g., search text) work without losing focus.

### Test 5: Auto-Hide on Pointer Departure
* **Actions**:
  1. Close active popups (click dismiss area or press `Escape`).
  2. Move cursor away from the bar into the fullscreen video/application.
* **Expected Outcome**:
  * `hideDelay` timer (default 300 ms) begins counting down.
  * After 300 ms, bar slides smoothly off-screen.
  * Fullscreen application retains focus and continues unobstructed.

### Test 6: Multi-Monitor Independence
* **Setup**: Multi-display workstation (e.g. eDP-1 + HDMI-A-1).
* **Actions**:
  1. Place fullscreen video on Monitor 1.
  2. Keep tiled code editor on Monitor 2.
  3. Move pointer between screens.
* **Expected Outcome**:
  * Monitor 1 enters peek mode (bar hidden, edge trigger active).
  * Monitor 2 maintains normal visible bar with exclusive zone.
  * No cross-monitor state contamination.

### Test 7: Shell Lifecycle & Hot Reload
* **Actions**:
  1. Execute `omarchy-restart-shell`.
  2. Modify a setting in `~/.config/omarchy/shell.json` (`triggerThickness`, `hideDelay`).
* **Expected Outcome**:
  * Shell restarts cleanly without zombie processes or layer-shell leaks.
  * Changes in `shell.json` apply immediately via `barConfig` binding.

---

## 3. Regression Verification Checklist

Before approving any pull request or commit, verify each item:

- [ ] Fullscreen application stays fullscreen (never leaves `fullscreen: 2`).
- [ ] Bar overlays fullscreen content at `WlrLayer.Overlay`.
- [ ] No window resizing, repositioning, or workspace displacement.
- [ ] No keyboard focus theft (`WlrKeyboardFocus.None` on bar and trigger).
- [ ] Zero hover flicker across trigger-bar boundary.
- [ ] Open popups keep the bar revealed until dismissed.
- [ ] Hide timer debounces cleanly after pointer departure.
- [ ] Idle CPU usage remains ~0.0%.
- [ ] No subprocess commands executed (e.g., no `hyprctl dispatch`).
- [ ] `omarchy plugin validate .` exits with code `0`.
