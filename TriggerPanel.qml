import QtQuick
import Quickshell
import Quickshell.Wayland

// TriggerPanel provides an edge-anchored, transparent layer-shell surface that
// catches pointer hover at the monitor edge while an application is fullscreen.
// Using WlrLayer.Overlay ensures it is placed above the fullscreen application.
// Setting exclusionMode to Ignore guarantees the fullscreen application is never
// resized, moved, or affected in any way.
PanelWindow {
  id: triggerWin

  required property var controller

  screen: controller.screen
  visible: controller.triggerVisible
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
