# AGENTS.md — PeekBar

This document contains executive instructions, architectural invariants, operational workflows, and guidelines for AI agents and human contributors working on the **PeekBar** codebase.

---

## 1. Project Mission & Principle

> **Core Principle: PeekBar overlays fullscreen; it never breaks fullscreen.**

PeekBar is an Omarchy/Quickshell `kind: bar` replacement plugin that provides edge-triggered bar reveal while applications are fullscreen.

* The fullscreen application must remain 100% fullscreen at all times.
* The application must never be resized, moved, or lose keyboard focus.
* The bar must never call `hyprctl dispatch fullscreen` or manipulate client window flags.
* All reveal behavior is achieved through Wayland layer-shell protocol semantics (`WlrLayer.Overlay`).

---

## 2. Documentation Index

To maintain modularity and avoid excessive file length, detailed specifications are separated into dedicated documents under [`docs/`](docs/):

| Document | Purpose |
| :--- | :--- |
| [`docs/requirements.md`](docs/requirements.md) | **Invariants & Requirements**: Core non-negotiables, functional specifications, state machine rules, and omarchyplugins.com compliance. |
| [`docs/architecture.md`](docs/architecture.md) | **Architecture & Protocol**: Component breakdown, Wayland layer-shell mechanics, Quickshell bindings, and universal popup flow. |
| [`docs/testing.md`](docs/testing.md) | **Testing & Quality Assurance**: Automated lint/validation suites, live manual test matrices, and regression checklists. |

---

## 3. Quick Architecture Overview

PeekBar is composed of 4 key modules in the repository root:

* [`manifest.json`](manifest.json): Omarchy plugin manifest conforming to `schemaVersion: 1`.
* [`Bar.qml`](Bar.qml): Entry point (`kind: bar`), housing the per-screen scope, stock bar widgets, and global popup lifecycle coordinator.
* [`PeekBarController.qml`](PeekBarController.qml): Per-monitor `QtObject` coordinating Hyprland fullscreen state, trigger hover, bar surface hover, popup state, and debounced timers.
* [`TriggerPanel.qml`](TriggerPanel.qml): 2px transparent layer-shell surface on `WlrLayer.Overlay` anchored to the monitor edge to detect pointer entry without blocking clicks.
* [`BarModel.js`](BarModel.js): Upstream layout normalization and slot calculation utilities.

---

## 4. Operational Invariants & Rules of Engagement

1. **Inspect Before Modifying**: Never guess Quickshell or Omarchy internal APIs. Always inspect the installed stock bar (`/usr/share/omarchy/shell/`) and running instances before proposing changes.
2. **Minimal Divergence**: Minimize differences between `Bar.qml` and upstream stock Omarchy bar so upstream fixes can be backported with minimal merge conflict.
3. **No Focus Theft**: Every layer window must enforce `WlrLayershell.keyboardFocus: WlrKeyboardFocus.None`. Never snoop on or intercept keystrokes.
4. **No Subprocess Invocations**: Do not invoke `bash -c`, `curl`, `wget`, or arbitrary shell scripts. All state must be event-driven via `Quickshell.Hyprland` signals.
5. **No Symlinks**: Keep the repository clean of symlinks to comply with `omarchy-plugin-validate`.
6. **Debounce Transitions**: All pointer exit logic must pass through debounced timers (`hideDelay`) to prevent flicker loops.
7. **Verify After Every Change**: Run the verification checklist in [`docs/testing.md`](docs/testing.md) after any edit.

---

## 5. Development & Verification Workflow

```bash
# Validate plugin structure and manifest schema
omarchy plugin validate .

# Lint QML files
qmllint -I /usr/share/omarchy/shell PeekBarController.qml TriggerPanel.qml

# Restart shell to test live
omarchy-restart-shell

# Inspect live logs
inst=$(quickshell list --all | grep Instance | awk '{print $2}' | tr -d ':')
quickshell log -f -i "$inst" | grep "PeekBar"
```
