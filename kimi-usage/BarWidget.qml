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

  readonly property var mainInstance: pluginApi?.mainInstance

  readonly property int weeklyUsed: mainInstance?.weeklyUsed ?? 0
  readonly property int weeklyRemaining: mainInstance?.weeklyRemaining ?? 0
  readonly property int weeklyLimit: mainInstance?.weeklyLimit ?? 0
  readonly property int fiveHourUsed: mainInstance?.fiveHourUsed ?? 0
  readonly property int fiveHourRemaining: mainInstance?.fiveHourRemaining ?? 0
  readonly property int fiveHourLimit: mainInstance?.fiveHourLimit ?? 0
  readonly property bool loading: mainInstance?.loading ?? false
  readonly property string errorString: mainInstance?.errorString ?? ""

  readonly property int weeklyUsedPercent: weeklyLimit > 0 ? Math.round((weeklyUsed / weeklyLimit) * 100) : 0
  readonly property int fiveHourUsedPercent: fiveHourLimit > 0 ? Math.round((fiveHourUsed / fiveHourLimit) * 100) : 0
  readonly property int maxUsedPercent: Math.max(weeklyUsedPercent, fiveHourUsedPercent)

  readonly property real contentWidth: capsuleRow.implicitWidth + Style.marginM * 2
  readonly property real contentHeight: capsuleHeight

  implicitWidth: isBarVertical ? capsuleHeight : contentWidth
  implicitHeight: isBarVertical ? contentHeight : capsuleHeight

  NPopupContextMenu {
    id: contextMenu
    model: [
      { "label": pluginApi?.tr("context.refresh") || "Refresh", "action": "refresh", "icon": "refresh" },
      { "label": pluginApi?.tr("context.settings") || "Settings", "action": "settings", "icon": "settings" }
    ]
    onTriggered: action => {
      contextMenu.close()
      PanelService.closeContextMenu(screen)
      if (action === "refresh") {
        root.mainInstance?.refresh()
      } else if (action === "settings") {
        if (pluginApi) BarService.openPluginSettings(screen, pluginApi.manifest)
      }
    }
  }

  Rectangle {
    id: visualCapsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.contentHeight
    color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
    radius: Style.radiusL
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    RowLayout {
      id: capsuleRow
      anchors.centerIn: parent
      spacing: Style.marginS

      function iconColorForUsage() {
        if (mouseArea.containsMouse) return Color.mOnHover
        if (root.errorString !== "") return Color.mError
        if (root.maxUsedPercent >= 90) return Color.mError
        if (root.maxUsedPercent >= 60) return Color.mWarning
        return "#22c55e"
      }

      NIcon {
        icon: "music"
        color: iconColorForUsage()
        applyUiScale: true
      }

      NText {
        visible: root.weeklyLimit > 0 || root.fiveHourLimit > 0
        text: "W:" + root.weeklyUsedPercent + "% 5H:" + root.fiveHourUsedPercent + "%"
        color: iconColorForUsage()
        pointSize: root.barFontSize - 1
        applyUiScale: false
        font.weight: Font.Bold
      }

      NText {
        visible: root.errorString !== "" && root.weeklyLimit === 0 && root.fiveHourLimit === 0
        text: "!"
        color: Color.mError
        pointSize: root.barFontSize
        applyUiScale: false
        font.weight: Font.Bold
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true

    onClicked: mouse => {
      if (mouse.button === Qt.LeftButton) {
        root.mainInstance?.refresh()
      } else if (mouse.button === Qt.RightButton) {
        PanelService.showContextMenu(contextMenu, root, screen)
      }
    }

    onEntered: {
      var tip = ""
      if (root.errorString !== "") {
        tip = (pluginApi?.tr("bar.error") || "Error") + ": " + root.errorString
      } else if (root.weeklyLimit === 0 && root.fiveHourLimit === 0) {
        tip = pluginApi?.tr("bar.noData") || "No data"
      } else {
        if (root.weeklyLimit > 0) {
          tip += (pluginApi?.tr("bar.weekly") || "Weekly") + ": " + root.weeklyUsed + "/" + root.weeklyLimit + " (" + root.weeklyUsedPercent + "% used)"
          let weeklyReset = root.mainInstance?.formatResetTime(root.mainInstance?.weeklyResetTime ?? "") ?? ""
          if (weeklyReset) tip += " — " + (pluginApi?.tr("bar.resetsIn") || "resets in") + " " + weeklyReset
        }
        if (root.fiveHourLimit > 0) {
          if (tip) tip += "\n"
          tip += (pluginApi?.tr("bar.fiveHour") || "5h") + ": " + root.fiveHourUsed + "/" + root.fiveHourLimit + " (" + root.fiveHourUsedPercent + "% used)"
          let fiveHourReset = root.mainInstance?.formatResetTime(root.mainInstance?.fiveHourResetTime ?? "") ?? ""
          if (fiveHourReset) tip += " — " + (pluginApi?.tr("bar.resetsIn") || "resets in") + " " + fiveHourReset
        }
      }
      TooltipService.show(root, tip, BarService.getTooltipDirection())
    }

    onExited: {
      TooltipService.hide()
    }
  }
}
