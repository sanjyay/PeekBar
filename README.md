# PeekBar

PeekBar is an Omarchy bar plugin that adds edge-triggered bar reveal while an application is in fullscreen.

PeekBar preserves the exact appearance, widgets, layout, and configuration of the stock Omarchy bar during normal use, while overlaying the bar seamlessly over fullscreen applications when the pointer reaches the monitor edge.

---

## The Experience

```text
NORMAL (tiled/floating windows)
┌─────────────────────────────────┐
│            PeekBar              │ (WlrLayer.Top, exclusive zone reserved)
├─────────────────────────────────┤
│                                 │
│           application           │
│                                 │
└─────────────────────────────────┘

FULLSCREEN (bar hidden)
┌─────────────────────────────────┐ ← 2px invisible overlay trigger
│                                 │
│                                 │
│       fullscreen application    │ (fullscreen undisturbed, exclusive zone = 0)
│                                 │
│                                 │
└─────────────────────────────────┘

FULLSCREEN + HOVER (bar revealed)
┌─────────────────────────────────┐
│            PeekBar              │ (WlrLayer.Overlay above fullscreen window)
├─────────────────────────────────┤
│                                 │
│       fullscreen application    │ (stays fullscreen, no resize or focus shift)
│                                 │
└─────────────────────────────────┘
```

When the pointer moves away from the revealed bar, PeekBar hides again after a debounced delay (default 300 ms).

---

## Key Features

- **True Overlay**: Overlays fullscreen windows using Wayland layer-shell (`WlrLayer.Overlay` with `exclusiveZone = 0`).
- **Zero Disturbance**: Fullscreen applications never leave fullscreen, never get resized, and never lose keyboard focus.
- **Per-Monitor Evaluation**: Fullscreen state is evaluated independently per monitor. If Monitor 1 has a fullscreen video and Monitor 2 has tiled windows, Monitor 2's bar remains normally visible.
- **Flicker-Free**: Dedicated reveal controller with debounced hide timers prevents flicker loops across the trigger-bar boundary.
- **Interactive Popups**: Keeps the bar revealed while interacting with widgets, popups, and menus.
- **Stock Omarchy Compatibility**: Full support for all Omarchy widgets, indicators, custom modules, drag-and-drop reordering, and themes.

---

## Installation

1. Link or clone this repository into your Omarchy plugins directory:

   ```bash
   ln -sfn /path/to/peekbar ~/.config/omarchy/plugins/peekbar
   ```

2. Enable PeekBar in `~/.config/omarchy/shell.json` by setting `"id": "peekbar"` inside the `"bar"` section:

   ```json
   {
     "bar": {
       "id": "peekbar",
       "revealInFullscreen": true,
       "triggerThickness": 2,
       "revealDelay": 0,
       "hideDelay": 300,
       "animationDuration": 150
     }
   }
   ```

3. Reload Omarchy shell or restart it:

   ```bash
   omarchy-restart-shell
   ```

---

## Configuration

PeekBar accepts the following configuration keys under the `"bar"` object in `~/.config/omarchy/shell.json`:

| Option | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `id` | `string` | `"peekbar"` | Plugin ID to activate PeekBar. |
| `revealInFullscreen` | `boolean` | `true` | Enable edge-triggered reveal in fullscreen. If `false`, acts like standard bar. |
| `triggerThickness` | `number` | `2` | Height/thickness of the top-edge trigger strip in logical pixels (1–20). |
| `revealDelay` | `number` | `0` | Delay in milliseconds before revealing the bar on hover. |
| `hideDelay` | `number` | `300` | Delay in milliseconds before hiding the bar after the pointer leaves. |
| `animationDuration` | `number` | `150` | Duration in milliseconds of the slide reveal/hide animation (`0` for instant). |

---

## State Model

```text
       NORMAL
         │
         │ fullscreen detected on monitor
         ▼
  FULLSCREEN_HIDDEN
         │
         │ pointer enters top-edge trigger
         ▼
 FULLSCREEN_REVEALED
         │
         │ pointer leaves bar & hideDelay expires
         ▼
  FULLSCREEN_HIDDEN
         │
         │ fullscreen ends on monitor
         ▼
       NORMAL
```

---

## Architecture

- **`manifest.json`**: Plugin declaration registering PeekBar as an Omarchy `kind: bar` plugin.
- **`PeekBarController.qml`**: State machine and event coordinator for each monitor. Listens to Hyprland monitor and workspace changes, coordinates trigger and bar hover states, and manages debounced timers.
- **`TriggerPanel.qml`**: Minimal transparent layer-shell surface (`WlrLayer.Overlay`, `exclusiveZone = 0`) that captures pointer edge entry without intercepting clicks or resizing windows.
- **`Bar.qml`**: Omarchy bar component integrating the peek reveal controller with stock Omarchy bar widgets, indicators, themes, and popup anchors.
- **`BarModel.js`**: Upstream layout and slot calculation helpers.

---

## License

MIT License. Portions adapted from upstream [Omarchy](https://github.com/omarchy/omarchy).
