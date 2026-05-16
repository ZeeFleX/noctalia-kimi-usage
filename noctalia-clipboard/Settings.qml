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

  function saveSettings() {
    if (!pluginApi || !pluginApi.pluginSettings) return

    pluginApi.pluginSettings.maxItems = parseInt(maxItemsInput.text) || (defaults.maxItems ?? 50)
    pluginApi.pluginSettings.previewWidth = parseInt(previewWidthInput.text) || (defaults.previewWidth ?? 60)
    pluginApi.pluginSettings.showCount = showCountCheck.text === "1"
    pluginApi.pluginSettings.persistFilter = persistFilterCheck.text === "1"

    pluginApi.saveSettings()
    Logger.i("NoctaliaClipboard", "Settings saved")
  }

  NText {
    Layout.fillWidth: true
    text: "Clipboard history settings"
    color: Color.mOnSurface
    pointSize: Style.fontSizeL
    font.weight: Font.Bold
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    NText {
      text: pluginApi?.tr("settings.maxItems") || "Max items in history"
      color: Color.mOnSurface
      pointSize: Style.fontSizeS
      Layout.preferredWidth: 200
    }

    NTextInput {
      id: maxItemsInput
      Layout.preferredWidth: 80
      label: ""
      text: String(cfg.maxItems ?? defaults.maxItems ?? 50)
      onTextChanged: root.saveSettings()
    }
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    NText {
      text: pluginApi?.tr("settings.previewWidth") || "Preview width (chars)"
      color: Color.mOnSurface
      pointSize: Style.fontSizeS
      Layout.preferredWidth: 200
    }

    NTextInput {
      id: previewWidthInput
      Layout.preferredWidth: 80
      label: ""
      text: String(cfg.previewWidth ?? defaults.previewWidth ?? 60)
      onTextChanged: root.saveSettings()
    }
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    NText {
      text: pluginApi?.tr("settings.showCount") || "Show count in bar"
      color: Color.mOnSurface
      pointSize: Style.fontSizeS
      Layout.preferredWidth: 200
    }

    NTextInput {
      id: showCountCheck
      Layout.preferredWidth: 80
      label: ""
      text: (cfg.showCount ?? defaults.showCount ?? true) ? "1" : "0"
      onTextChanged: root.saveSettings()
    }
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    NText {
      text: pluginApi?.tr("settings.persistFilter") || "Keep search filter between opens"
      color: Color.mOnSurface
      pointSize: Style.fontSizeS
      Layout.preferredWidth: 200
    }

    NTextInput {
      id: persistFilterCheck
      Layout.preferredWidth: 80
      label: ""
      text: (cfg.persistFilter ?? defaults.persistFilter ?? true) ? "1" : "0"
      onTextChanged: root.saveSettings()
    }
  }

  NText {
    Layout.fillWidth: true
    text: "Tip: enter 1 for true, 0 for false"
    color: Color.mOnSurfaceVariant
    pointSize: Style.fontSizeXS
  }

  Item {
    Layout.fillHeight: true
  }
}
