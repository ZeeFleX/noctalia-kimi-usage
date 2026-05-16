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
  readonly property int maxItems: parseInt(cfg.maxItems ?? defaults.maxItems ?? 50) || 50
  readonly property int previewWidth: parseInt(cfg.previewWidth ?? defaults.previewWidth ?? 60) || 60
  readonly property bool showCount: (cfg.showCount ?? defaults.showCount ?? true) ? true : false

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

      var tabIndex = line.indexOf("\t")
      if (tabIndex < 0) continue

      var id = line.substring(0, tabIndex)
      var preview = line.substring(tabIndex + 1)

      var isImage = preview === "" || preview.indexOf("\u0000") >= 0

      items.push({
        id: id,
        preview: isImage ? (pluginApi?.tr("popup.image") || "[Image]") : truncate(preview, previewWidth),
        fullText: preview,
        isImage: isImage
      })
    }

    clipboardItems = items
    itemCount = items.length
    applyFilter()
  }

  function truncate(text, maxLen) {
    if (!text || text.length <= maxLen) return text || ""
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
      var full = (item.fullText || "").toLowerCase()
      var prev = (item.preview || "").toLowerCase()
      if (full.indexOf(lowerFilter) >= 0 || prev.indexOf(lowerFilter) >= 0) {
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
    clipboardPopup.close()
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
    clipboardPopup.close()
  }

  Timer {
    id: refreshTimer
    interval: 3000
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

  // Popup for clipboard history
  Popup {
    id: clipboardPopup
    x: root.width / 2 - width / 2
    y: root.height + 4
    width: 420
    height: Math.min(500, listLayout.implicitHeight + headerLayout.implicitHeight + footerLayout.implicitHeight + 40)
    padding: Style.marginM
    modal: false
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

    background: Rectangle {
      color: Style.capsuleColor
      radius: Style.radiusL
      border.color: Style.capsuleBorderColor
      border.width: 1
    }

    ColumnLayout {
      anchors.fill: parent
      spacing: Style.marginS

      // Header with search
      RowLayout {
        id: headerLayout
        Layout.fillWidth: true
        spacing: Style.marginS

        NTextInput {
          id: searchField
          Layout.fillWidth: true
          label: ""
          placeholderText: pluginApi?.tr("popup.search") || "Search..."
          text: root.searchFilter
          onTextChanged: {
            root.searchFilter = text
            root.applyFilter()
          }
        }

        NText {
          text: "✕"
          color: Color.mOnSurfaceVariant
          pointSize: Style.fontSizeL
          MouseArea {
            anchors.fill: parent
            onClicked: clipboardPopup.close()
            cursorShape: Qt.PointingHandCursor
          }
        }
      }

      // Items list
      ListView {
        id: itemsList
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: root.filteredItems
        spacing: 1

        delegate: Rectangle {
          required property var modelData
          required property int index

          width: itemsList.width
          height: itemRow.implicitHeight + Style.marginS * 2
          color: itemMouse.containsMouse ? Color.withOpacity(Color.mSurfaceVariant, 0.5) : "transparent"
          radius: Style.radiusS

          RowLayout {
            id: itemRow
            anchors.fill: parent
            anchors.margins: Style.marginS
            spacing: Style.marginS

            NText {
              Layout.fillWidth: true
              text: modelData.preview
              color: Color.mOnSurface
              pointSize: Style.fontSizeS
              wrapMode: Text.WrapAnywhere
              maximumLineCount: 2
              elide: Text.ElideRight
            }

            NText {
              text: "🗑"
              visible: itemMouse.containsMouse
              color: Color.mError
              pointSize: Style.fontSizeS
              MouseArea {
                anchors.fill: parent
                onClicked: root.deleteItem(modelData.id)
                cursorShape: Qt.PointingHandCursor
              }
            }
          }

          MouseArea {
            id: itemMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.pasteItem(modelData.id)
            cursorShape: Qt.PointingHandCursor
          }
        }

        NText {
          visible: parent.count === 0
          anchors.centerIn: parent
          text: root.searchFilter !== ""
            ? (pluginApi?.tr("popup.empty") || "No matching items")
            : (pluginApi?.tr("popup.empty") || "Clipboard history is empty")
          color: Color.mOnSurfaceVariant
          pointSize: Style.fontSizeS
        }
      }

      // Footer
      RowLayout {
        id: footerLayout
        Layout.fillWidth: true
        spacing: Style.marginS

        Item {
          Layout.fillWidth: true
        }

        NText {
          text: pluginApi?.tr("popup.clear") || "Clear history"
          color: Color.mError
          pointSize: Style.fontSizeS
          MouseArea {
            anchors.fill: parent
            onClicked: root.clearHistory()
            cursorShape: Qt.PointingHandCursor
          }
        }
      }
    }

    onAboutToShow: {
      root.refreshClipboardList()
      var persist = cfg.persistFilter ?? defaults.persistFilter ?? true
      if (!persist) {
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
        clipboardPopup.open()
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
