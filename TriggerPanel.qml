import QtQuick
import Quickshell
import Quickshell.Wayland

// TriggerPanel provides an edge-anchored, transparent layer-shell surface that
// catches pointer hover at the monitor edge while an application is fullscreen.
// Using WlrLayer.Overlay ensures it is placed above the fullscreen application.
// Setting exclusionMode to Ignore guarantees the fullscreen application is never
// resized, moved, or affected in any way.
//
// The trigger stays mapped whenever fullscreen is active — even after the bar
// reveals — so the cursor sliding from the 2px trigger into the bar surface
// is always covered by at least one hover surface. When the bar is revealed and
// sits at margin 0, the trigger (2px tall) is hidden behind the bar (35px tall),
// so it is visually invisible but still receives pointer events at y=0..1.
PanelWindow {
  id: triggerWin

  required property var controller

  screen: controller.screen
  // Keep mapped for the entire duration of fullscreen — see comment above.
  visible: controller.isFullscreen
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"
  surfaceFormat.opaque: false

  WlrLayershell.namespace: "omarchy-peekbar-trigger"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  // Anchors follow the configured bar position.
  anchors {
    top: controller.position === "top" || (controller.vertical && (controller.position === "left" || controller.position === "right"))
    bottom: controller.position === "bottom" || (controller.vertical && (controller.position === "left" || controller.position === "right"))
    left: controller.position === "left" || (!controller.vertical && (controller.position === "top" || controller.position === "bottom"))
    right: controller.position === "right" || (!controller.vertical && (controller.position === "top" || controller.position === "bottom"))
  }

  implicitWidth: controller.vertical ? controller.triggerThickness : 0
  implicitHeight: controller.vertical ? 0 : controller.triggerThickness

  Item {
    anchors.fill: parent

    HoverHandler {
      id: triggerHoverHandler
      onHoveredChanged: controller.triggerHovered = hovered
      Component.onDestruction: if (hovered) controller.triggerHovered = false
    }
  }
}
