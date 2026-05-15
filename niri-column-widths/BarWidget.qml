import QtQuick
import QtQuick.Layouts
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
  readonly property var presets: cfg.presets ?? defaults.presets ?? ["33%", "50%", "66%"]

  readonly property real contentWidth: capsuleRow.implicitWidth + Style.marginM * 2
  readonly property real contentHeight: capsuleHeight

  implicitWidth: isBarVertical ? capsuleHeight : contentWidth
  implicitHeight: isBarVertical ? contentHeight : capsuleHeight

  function setColumnWidth(widthValue) {
    Quickshell.execDetached(["niri", "msg", "action", "set-column-width", widthValue])
    Logger.i("NiriColumnWidths", "Set column width to " + widthValue)
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
      id: capsuleRow
      anchors.centerIn: parent
      spacing: 0

      Repeater {
        model: root.presets

        Item {
          id: presetBtn
          required property string modelData
          required property int index

          Layout.preferredWidth: btnText.implicitWidth + Style.marginS * 2
          Layout.preferredHeight: root.capsuleHeight

          NText {
            id: btnText
            anchors.centerIn: parent
            text: presetLabel(modelData)
            color: btnMouse.containsMouse ? Color.mOnHover : Color.mOnSurface
            pointSize: root.barFontSize - 1
            applyUiScale: false
            font.weight: Font.Normal
          }

          Rectangle {
            visible: presetBtn.index < root.presets.length - 1
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: root.capsuleHeight * 0.5
            color: Style.capsuleBorderColor
          }

          MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.setColumnWidth(presetBtn.modelData)
            cursorShape: Qt.PointingHandCursor
          }
        }
      }
    }
  }

  function presetLabel(value) {
    if (value === "33%" || value === "0.33333") return "⅓"
    if (value === "50%" || value === "0.5") return "½"
    if (value === "66%" || value === "66.667%" || value === "0.66667") return "⅔"
    if (value === "25%" || value === "0.25") return "¼"
    if (value === "75%" || value === "0.75") return "¾"
    return value
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    acceptedButtons: Qt.RightButton
    hoverEnabled: true

    onClicked: {
      if (pluginApi) BarService.openPluginSettings(screen, pluginApi.manifest)
    }

    onEntered: {
      TooltipService.show(root, pluginApi?.tr("bar.tooltip") || "Niri column width presets", BarService.getTooltipDirection())
    }

    onExited: {
      TooltipService.hide()
    }
  }
}
