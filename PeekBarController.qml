import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// PeekBarController coordinates the fullscreen detection and reveal state
// machine for a single monitor. Isolating this per-monitor controller ensures
// that multi-monitor setups behave independently without global state pollution.
QtObject {
  id: controller

  // Injected by the owning Scope/Bar
  required property var screen
  required property bool barHidden
  required property real barSize
  required property string position
  required property bool vertical

  // User configuration options
  property bool revealInFullscreen: true
  property int triggerThickness: 2
  property int revealDelay: 0
  property int hideDelay: 300
  property int animationDuration: 150

  // Monitor identity
  readonly property string screenName: screen && screen.name ? String(screen.name) : ""
  readonly property var hyprMonitor: Hyprland.monitorFor(screen)
  readonly property var activeWs: hyprMonitor ? hyprMonitor.activeWorkspace : null

  // True if a window on this monitor's active workspace is currently fullscreen
  readonly property bool isFullscreen: revealInFullscreen && !!(activeWs && activeWs.hasFullscreen)

  // Explicit state model constants matching AGENTS.md
  readonly property int stateNormal: 0
  readonly property int stateFullscreenHidden: 1
  readonly property int stateFullscreenRevealed: 2

  // Reveal & hover state
  property bool revealed: false
  property bool triggerHovered: false
  property bool barSurfaceHovered: false
  property bool popupHovered: false
  property bool revealHold: false

  // Emitted when hide timer expires so Bar can dismiss any active widget popup
  signal closePopoutRequested()

  // Pointer is considered active if cursor is over trigger, bar, active popup,
  // or held during entry animation so unmapping the trigger doesn't flicker.
  readonly property bool pointerActive: triggerHovered || barSurfaceHovered || popupHovered || revealHold

  // The canonical state machine state
  readonly property int currentState: {
    if (!isFullscreen) return stateNormal
    return revealed ? stateFullscreenRevealed : stateFullscreenHidden
  }

  // Margin targets for bar positioning and slide animations.
  // In fullscreen mode, hidden bars park just off-screen (-barSize).
  // When revealed, they return to margin 0 at WlrLayer.Overlay.
  readonly property real targetMarginTop: {
    if (position !== "top") return 0
    if (barHidden) return -barSize
    if (isFullscreen) return revealed ? 0 : -barSize
    return 0
  }

  readonly property real targetMarginBottom: {
    if (position !== "bottom") return 0
    if (barHidden) return -barSize
    if (isFullscreen) return revealed ? 0 : -barSize
    return 0
  }

  readonly property real targetMarginLeft: {
    if (position !== "left") return 0
    if (barHidden) return -barSize
    if (isFullscreen) return revealed ? 0 : -barSize
    return 0
  }

  readonly property real targetMarginRight: {
    if (position !== "right") return 0
    if (barHidden) return -barSize
    if (isFullscreen) return revealed ? 0 : -barSize
    return 0
  }

  // Wayland layer-shell rules:
  // Normal: layer = Top, exclusiveZone = Auto
  // Fullscreen: layer = Overlay, exclusiveZone = 0 (ExclusionMode.Ignore)
  readonly property int exclusionMode: (barHidden || isFullscreen) ? ExclusionMode.Ignore : ExclusionMode.Auto
  readonly property int layer: isFullscreen ? WlrLayer.Overlay : WlrLayer.Top

  // Top-edge trigger surface is only mapped while in fullscreen and the bar is not revealed
  readonly property bool triggerVisible: isFullscreen && !revealed

  onIsFullscreenChanged: {
    if (isFullscreen) {
      console.log("PeekBar: fullscreen entered on " + (screenName || "display"))
      revealed = false
      revealHold = false
      revealTimer.stop()
      revealHoldTimer.stop()
      hideTimer.stop()
    } else {
      console.log("PeekBar: fullscreen exited on " + (screenName || "display"))
      revealed = false
      revealHold = false
      revealTimer.stop()
      revealHoldTimer.stop()
      hideTimer.stop()
    }
  }

  onRevealedChanged: {
    if (revealed) {
      console.log("PeekBar: bar revealed on " + (screenName || "display"))
      // Hold pointerActive during entry animation so unmapping the trigger surface
      // does not cause a premature hide countdown before the bar arrives under pointer.
      revealHold = true
      revealHoldTimer.restart()
    } else if (isFullscreen) {
      console.log("PeekBar: bar hidden on " + (screenName || "display"))
      revealHold = false
      revealHoldTimer.stop()
    }
  }

  onPointerActiveChanged: {
    if (!isFullscreen) return
    if (pointerActive) {
      hideTimer.stop()
      if (!revealed && triggerHovered) {
        if (revealDelay > 0) {
          revealTimer.restart()
        } else {
          revealed = true
        }
      }
    } else {
      revealTimer.stop()
      if (revealed) {
        hideTimer.restart()
      }
    }
  }

  // Grace period timer while the bar is sliding into view
  property var revealHoldTimer: Timer {
    interval: Math.max(100, controller.animationDuration + 100)
    repeat: false
    onTriggered: {
      controller.revealHold = false
      if (controller.revealed && !controller.pointerActive && controller.isFullscreen) {
        controller.hideTimer.restart()
      }
    }
  }

  // Reveal timer for configurable reveal delay
  property var revealTimer: Timer {
    interval: controller.revealDelay
    repeat: false
    onTriggered: {
      if (controller.triggerHovered) {
        controller.revealed = true
      }
    }
  }

  // Hide timer with debouncing to prevent flicker
  property var hideTimer: Timer {
    interval: controller.hideDelay
    repeat: false
    onTriggered: {
      if (!controller.pointerActive) {
        controller.revealed = false
        controller.closePopoutRequested()
      }
    }
  }
}
