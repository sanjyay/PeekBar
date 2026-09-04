import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// PeekBarController coordinates the fullscreen detection and reveal state
// machine for a single monitor. Isolating this per-monitor controller ensures
// that multi-monitor setups behave independently without global state pollution.
//
// State machine:
//   NORMAL              → no fullscreen window
//   FULLSCREEN_HIDDEN   → fullscreen window, bar parked off-screen
//   FULLSCREEN_REVEALED → fullscreen window, bar visible at top
//
// pointerActive = trigger OR bar surface OR active popup
// Trigger stays visible (mapped) even when bar is revealed so that
// the cursor sliding from trigger → bar never loses hover continuity.
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

  // Individual hover inputs — set by Bar.qml and TriggerPanel.qml
  property bool triggerHovered: false
  property bool barSurfaceHovered: false
  property bool popupHovered: false     // Set by Bar.qml's popout tracking

  // Derived: pointer is over any part of the peekbar system
  readonly property bool pointerActive: triggerHovered || barSurfaceHovered || popupHovered

  // Reveal state
  property bool revealed: false

  // Emitted when hide timer fires so Bar can dismiss any open widget popup
  signal closePopoutRequested()

  // The canonical state machine state
  readonly property int currentState: {
    if (!isFullscreen) return stateNormal
    return revealed ? stateFullscreenRevealed : stateFullscreenHidden
  }

  // Margin targets for bar positioning and slide animations.
  // Hidden bars park just off-screen (-barSize). Revealed bars sit at margin 0.
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

  // The trigger surface stays visible whenever fullscreen is active.
  // Keeping it mapped even when revealed means the cursor sliding between
  // trigger and bar never has a gap where hover is on neither surface.
  // The trigger is placed above the fullscreen app but below the bar in the
  // overlay stack. Being 2px tall it is invisible behind the 35px bar.
  readonly property bool triggerVisible: isFullscreen

  onIsFullscreenChanged: {
    if (isFullscreen) {
      console.log("PeekBar: fullscreen entered on " + (screenName || "display"))
    } else {
      console.log("PeekBar: fullscreen exited on " + (screenName || "display"))
    }
    // Always reset on fullscreen state change
    revealed = false
    revealTimer.stop()
    hideTimer.stop()
  }

  onRevealedChanged: {
    if (revealed) {
      console.log("PeekBar: bar revealed on " + (screenName || "display"))
    } else if (isFullscreen) {
      console.log("PeekBar: bar hidden on " + (screenName || "display"))
    }
  }

  // React to trigger hover: start reveal when entering, start hide when leaving
  onTriggerHoveredChanged: {
    if (!isFullscreen) return
    if (triggerHovered) {
      hideTimer.stop()
      if (!revealed) {
        if (revealDelay > 0) {
          revealTimer.restart()
        } else {
          revealed = true
        }
      }
    } else {
      // Trigger left — only start hide if bar and popup are also not hovered
      revealTimer.stop()
      if (!barSurfaceHovered && !popupHovered && revealed) {
        hideTimer.restart()
      }
    }
  }

  // React to bar surface hover: cancel hide when entering, start hide when leaving
  onBarSurfaceHoveredChanged: {
    if (!isFullscreen) return
    if (barSurfaceHovered) {
      hideTimer.stop()
    } else {
      if (!triggerHovered && !popupHovered && revealed) {
        hideTimer.restart()
      }
    }
  }

  // React to popup hover: cancel hide when entering, start hide when leaving
  onPopupHoveredChanged: {
    if (!isFullscreen) return
    if (popupHovered) {
      hideTimer.stop()
    } else {
      if (!triggerHovered && !barSurfaceHovered && revealed) {
        hideTimer.restart()
      }
    }
  }

  // Reveal timer for configurable reveal delay
  property var revealTimer: Timer {
    interval: controller.revealDelay
    repeat: false
    onTriggered: {
      if (controller.triggerHovered && controller.isFullscreen) {
        controller.revealed = true
      }
    }
  }

  // Hide timer — debounced so brief pointer gaps don't flicker
  property var hideTimer: Timer {
    interval: controller.hideDelay
    repeat: false
    onTriggered: {
      if (!controller.pointerActive && controller.isFullscreen) {
        controller.revealed = false
        controller.closePopoutRequested()
      }
    }
  }
}
