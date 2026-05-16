import QtQuick
import qs.Commons

Item {
  id: root
  property var pluginApi: null

  // Ensure cliphist watcher is running
  Component.onCompleted: {
    Logger.i("NoctaliaClipboard", "Plugin loaded")
    // cliphist store should be running via wl-paste --watch cliphist store
    // If not, user should add it to autostart
  }
}
