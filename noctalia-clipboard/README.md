# Noctalia Clipboard

Clipboard history manager for [Noctalia](https://github.com/ZeeFleX/noctalia) status bar. Inspired by Paste for macOS.

Powered by [`cliphist`](https://github.com/sentriz/cliphist) — lightweight Wayland clipboard manager.

## Features

- 📋 **History in status bar** — click icon to browse recent copies
- 🔍 **Search** — filter by text, instant results
- 🖼️ **Images support** — detects binary/image clipboard entries
- 🗑️ **Right-click to delete** — remove individual items
- 🧹 **Clear history** — wipe all from menu
- 🎨 **Noctalia style** — matches your bar theme automatically
- 🌍 **i18n** — English and Russian included

## Demo

```
📋 42         ← bar widget (click to open)
├─ Search...  ← type to filter
├─ ──────────
├─ https://github.com/...
├─ Implement authentication...
├─ [Image]
├─ npm install -g ...
├─ ──────────
└─ Clear history
```

## Requirements

- [Niri](https://github.com/YaLTeR/niri) or any Wayland compositor
- [Noctalia](https://github.com/ZeeFleX/noctalia) ≥ 3.6.0
- [`cliphist`](https://github.com/sentriz/cliphist) — clipboard database
- [`wl-clipboard`](https://github.com/bugaevc/wl-clipboard) — `wl-copy`, `wl-paste`

### Install dependencies

**Arch / CachyOS:**
```bash
sudo pacman -S cliphist wl-clipboard
```

**Enable clipboard watcher** (add to autostart):
```bash
wl-paste --watch cliphist store
```

## Installation

Add as Noctalia custom source:
```
https://github.com/ZeeFleX/noctalia-plugins
```

Then install **Noctalia Clipboard** from plugin browser.

## Settings

| Setting | Default | Description |
|---------|---------|-------------|
| Max items | 50 | How many clipboard entries to show |
| Preview width | 60 | Truncate long text to N characters |
| Show count | true | Show "📋 42" counter in bar |
| Persist filter | true | Keep search text between opens |

## Usage

1. Copy anything — text, image, link
2. Click **📋** in Noctalia bar
3. Type to search or click to paste
4. Right-click item to delete it

## Keyboard shortcut

Noctalia plugins currently don't support global hotkeys. To open clipboard with a shortcut, bind in your compositor:

**Niri config:**
```kdl
binds {
    Mod+Shift+V { spawn "sh" "-c" "wl-paste --watch cliphist store &"; }
}
```

Or use a launcher script that clicks the bar widget via `ydotool`/`wtype`.

## License

MIT — Ilya Kardapolov (ZeeFleX)
