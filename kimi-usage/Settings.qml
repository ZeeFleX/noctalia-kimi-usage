import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL

  property var pluginApi: null
  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  property string editApiKey: cfg.apiKey ?? defaults.apiKey ?? ""
  property string editApiEndpoint: cfg.apiEndpoint ?? defaults.apiEndpoint ?? "https://api.kimi.com/coding/v1/usages"

  function saveSettings() {
    if (!pluginApi || !pluginApi.pluginSettings) {
      Logger.e("KimiUsage", "Cannot save: pluginApi or pluginSettings is null")
      return
    }

    pluginApi.pluginSettings.apiKey = root.editApiKey
    pluginApi.pluginSettings.apiEndpoint = root.editApiEndpoint
    pluginApi.saveSettings()
    Logger.i("KimiUsage", "Settings saved")

    if (pluginApi.mainInstance) {
      pluginApi.mainInstance.refresh()
    }
  }

  NTextInput {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.apiKey") || "API Key"
    description: pluginApi?.tr("settings.apiKeyDesc") || "Your Kimi API key"
    placeholderText: "sk-..."
    text: root.editApiKey
    onTextChanged: root.editApiKey = text
    inputItem.echoMode: TextInput.Password
  }

  NTextInput {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.endpoint") || "Endpoint"
    description: pluginApi?.tr("settings.endpointDesc") || "API endpoint for usage data"
    placeholderText: "https://api.kimi.com/coding/v1/usages"
    text: root.editApiEndpoint
    onTextChanged: root.editApiEndpoint = text
  }

  Item {
    Layout.fillHeight: true
  }
}
