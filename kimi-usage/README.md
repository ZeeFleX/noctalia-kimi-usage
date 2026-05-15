# noctalia-kimi-usage

Noctalia (Quickshell) plugin that displays **Kimi AI** usage limits in your status bar.

## Features

- **Weekly limit** — shows remaining weekly quota percentage
- **5-hour limit** — shows remaining 5-hour rolling window quota percentage
- **Smart colors** — icon turns yellow at ≤50% and red at ≤20%
- **Tooltip details** — exact numbers and time until reset on hover
- **Auto-refresh** — updates every 60 seconds

## Preview

```
[brain icon] W:84% 5H:100%
```

## Requirements

- [Noctalia](https://github.com/noctalia-dev/noctalia) (Quickshell-based desktop shell)
- Kimi Code API key (`KIMI_API_KEY`)

## Installation

### Via Noctalia Plugin Manager

1. Open **Noctalia Settings → Plugins → Sources**
2. Add new source:
   - **Name**: `Kimi Usage`
   - **URL**: `https://github.com/ZeeFleX/noctalia-kimi-usage`
3. Install `kimi-usage` from the plugin list

### Manual

```bash
cd ~/.config/noctalia/plugins
git clone https://github.com/ZeeFleX/noctalia-kimi-usage.git kimi-usage
```

Then add to `~/.config/noctalia/plugins.json`:

```json
"kimi-usage": {
    "enabled": true
}
```

And add the widget to your bar in `~/.config/noctalia/settings.json` under `bar.widgets.right` (or `left`/`center`):

```json
{
    "defaultSettings": {
        "apiEndpoint": "https://api.kimi.com/coding/v1/usages",
        "apiKey": ""
    },
    "id": "plugin:kimi-usage"
}
```

## Configuration

Open **Noctalia Settings → Plugins → Kimi Usage** and set your API key.

| Setting | Default | Description |
|---------|---------|-------------|
| `apiKey` | `''` | Your Kimi Code API key |
| `apiEndpoint` | `https://api.kimi.com/coding/v1/usages` | Usage endpoint URL |

> **Note:** This plugin uses the **Kimi Code** endpoint (`api.kimi.com`), not the Moonshot OpenPlatform balance endpoint. If you need balance display for `api.moonshot.ai`, open an issue.

## API Key

Get your API key from [Kimi Code CLI](https://github.com/MoonshotAI/Kimi-Chat) settings or Kimi developer console.

## License

MIT
