import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  readonly property string screenName: screen?.name ?? ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

  readonly property var cfg: pluginApi?.pluginSettings ?? ({})
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings ?? ({})
  readonly property int maxItems: cfg.maxItems ?? defaults.maxItems ?? 50
  readonly property int previewWidth: cfg.previewWidth ?? defaults.previewWidth ?? 60
  readonly property bool showCount: cfg.showCount ?? defaults.showCount ?? true

  readonly property real contentWidth: {
    if (showCount && itemCount > 0) {
      return iconLayout.implicitWidth + countText.implicitWidth + Style.marginM * 3
    }
    return iconLayout.implicitWidth + Style.marginM * 2
  }
  readonly property real contentHeight: capsuleHeight

  implicitWidth: isBarVertical ? capsuleHeight : contentWidth
  implicitHeight: isBarVertical ? contentHeight : capsuleHeight

  // Clipboard items storage
  property var clipboardItems: []
  property var filteredItems: []
  property int itemCount: 0
  property string searchFilter: ""

  function refreshClipboardList() {
    Quickshell.execDetached(["bash", "-c",
      "cliphist list | head -n " + maxItems + " > /tmp/noctalia-clipboard-list.txt"
    ])

    // Read file after short delay
    Qt.callLater(function() {
      var xhr = new XMLHttpRequest()
      xhr.open("GET", "file:///tmp/noctalia-clipboard-list.txt")
      xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
          parseClipboardList(xhr.responseText)
        }
      }
      xhr.send()
    })
  }

  function parseClipboardList(text) {
    var items = []
    var lines = text.split("\n")
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      if (line === "") continue

      // Format: "ID\tpreview_text"
      var tabIndex = line.indexOf("\t")
      if (tabIndex < 0) continue

      var id = line.substring(0, tabIndex)
      var preview = line.substring(tabIndex + 1)

      // Detect images (cliphist stores images with binary data, preview shows as empty or special)
      var isImage = preview.startsWith("\u0000") || preview === "" || preview.indexOf("[image]") >= 0

      items.push({
        id: id,
        preview: isImage ? pluginApi?.tr("popup.image") || "[Image]" : truncate(preview, previewWidth),
        fullText: preview,
        isImage: isImage
      })
    }

    clipboardItems = items
    itemCount = items.length
    applyFilter()
  }

  function truncate(text, maxLen) {
    if (text.length <= maxLen) return text
    return text.substring(0, maxLen) + "…"
  }

  function applyFilter() {
    if (searchFilter === "") {
      filteredItems = clipboardItems
      return
    }

    var filtered = []
    var lowerFilter = searchFilter.toLowerCase()
    for (var i = 0; i < clipboardItems.length; i++) {
      var item = clipboardItems[i]
      if (item.fullText.toLowerCase().indexOf(lowerFilter) >= 0 ||
          item.preview.toLowerCase().indexOf(lowerFilter) >= 0) {
        filtered.push(item)
      }
    }
    filteredItems = filtered
  }

  function pasteItem(itemId) {
    Quickshell.execDetached(["bash", "-c",
      "cliphist decode " + itemId + " | wl-copy"
    ])
    Logger.i("NoctaliaClipboard", "Pasted item " + itemId)
    clipboardMenu.close()
  }

  function deleteItem(itemId) {
    Quickshell.execDetached(["cliphist", "delete", itemId])
    Logger.i("NoctaliaClipboard", "Deleted item " + itemId)
    refreshClipboardList()
  }

  function clearHistory() {
    Quickshell.execDetached(["cliphist", "wipe"])
    Logger.i("NoctaliaClipboard", "History cleared")
    refreshClipboardList()
    clipboardMenu.close()
  }

  // Update list periodically and on show
  Timer {
    id: refreshTimer
    interval: 2000
    running: true
    repeat: true
    onTriggered: root.refreshClipboardList()
  }

  Component.onCompleted: {
    refreshClipboardList()
  }

  Rectangle {
    id: visualCapsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.contentHeight
    color: Style.capsuleColor
    radius: Style.radiusL
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    RowLayout {
      id: iconLayout
      anchors.centerIn: parent
      spacing: Style.marginS

      NText {
        text: "📋"
        color: Color.mOnSurface
        pointSize: root.barFontSize
        applyUiScale: false
      }

      NText {
        id: countText
        visible: root.showCount && root.itemCount > 0
        text: String(root.itemCount)
        color: Color.mOnSurfaceVariant
        pointSize: root.barFontSize - 2
        applyUiScale: false
        font.weight: Font.Normal
      }
    }
  }

  // Clipboard history menu
  Menu {
    id: clipboardMenu

    // Search field
    MenuItem {
      enabled: false
      height: searchField.height + Style.marginS * 2

      contentItem: NTextInput {
        id: searchField
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Style.marginS
        label: pluginApi?.tr("popup.search") || "Search..."
        placeholderText: pluginApi?.tr("popup.search") || "Search..."
        text: root.searchFilter
        onTextChanged: {
          root.searchFilter = text
          root.applyFilter()
        }
      }
    }

    MenuSeparator {}

    // History items
    Repeater {
      model: root.filteredItems

      MenuItem {
        required property var modelData
        required property int index

        text: modelData.preview
        enabled: true

        onTriggered: root.pasteItem(modelData.id)

        // Right-click to delete
        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.RightButton
          onClicked: root.deleteItem(modelData.id)
        }
      }
    }

    // Empty state
    MenuItem {
      visible: root.filteredItems.length === 0
      enabled: false
      text: root.searchFilter !== ""
        ? (pluginApi?.tr("popup.empty") || "No matching items")
        : (pluginApi?.tr("popup.empty") || "Clipboard history is empty")
    }

    MenuSeparator {
      visible: root.filteredItems.length > 0
    }

    // Clear history
    MenuItem {
      visible: root.itemCount > 0
      text: pluginApi?.tr("popup.clear") || "Clear history"
      onTriggered: root.clearHistory()
    }

    onAboutToShow: {
      root.refreshClipboardList()
      if (!cfg.persistFilter) {
        root.searchFilter = ""
        searchField.text = ""
      }
      root.applyFilter()
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true

    onClicked: {
      if (mouse.button === Qt.LeftButton) {
        clipboardMenu.popup()
      } else if (mouse.button === Qt.RightButton) {
        if (pluginApi) BarService.openPluginSettings(screen, pluginApi.manifest)
      }
    }

    onEntered: {
      TooltipService.show(root, pluginApi?.tr("bar.tooltip") || "Clipboard history (click to browse)", BarService.getTooltipDirection())
    }

    onExited: {
      TooltipService.hide()
    }
  }
}
