import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL

  property var pluginApi: null
  property var cfg: pluginApi?.pluginSettings ?? ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings ?? ({})

  property var editPresets: {
    let p = cfg.presets ?? defaults.presets ?? ["33%", "50%", "66%"]
    return p.join(", ")
  }

  function saveSettings() {
    if (!pluginApi || !pluginApi.pluginSettings) return

    let raw = editPresets
    let arr = raw.split(",").map(function(s) { return s.trim() }).filter(function(s) { return s !== "" })
    if (arr.length === 0) arr = defaults.presets ?? ["33%", "50%", "66%"]
    pluginApi.pluginSettings.presets = arr
    pluginApi.saveSettings()
    Logger.i("NiriColumnWidths", "Settings saved: " + arr.join(", "))
  }

  NText {
    Layout.fillWidth: true
    text: pluginApi?.tr("settings.presetsDesc") || "Enter up to 5 presets separated by commas. Supported: 33%, 50%, 66%, fixed 500, +10%, -10%, etc."
    color: Color.mOnSurface
    pointSize: Style.fontSizeS
    wrapMode: Text.Wrap
  }

  NTextInput {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.presets") || "Presets"
    placeholderText: "33%, 50%, 66%"
    text: root.editPresets
    onTextChanged: root.editPresets = text
  }

  Item {
    Layout.fillHeight: true
  }
}
