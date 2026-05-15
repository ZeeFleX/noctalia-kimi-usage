# Niri Column Widths

Noctalia plugin for quick column width presets in the **Niri** Wayland compositor.

## Features

- Three clickable buttons in the status bar: **⅓ | ½ | ⅔**
- Customizable presets via settings (percentages, fixed pixels, relative changes)
- Clean, compact capsule design matching Noctalia style

## Presets

Default presets:
- `33%` → **⅓**
- `50%` → **½**
- `66%` → **⅔**

You can customize them in plugin settings. Supported formats:
- `33%`, `50%`, `66%` — proportions
- `fixed 500` — fixed pixel width
- `+10%`, `-10%` — relative changes

## Requirements

- [Niri](https://github.com/YaLTeR/niri) compositor
- `niri` CLI available in `$PATH`

## Installation

Add as a Noctalia custom source:
```
https://github.com/ZeeFleX/noctalia-plugins
```

## License

MIT
