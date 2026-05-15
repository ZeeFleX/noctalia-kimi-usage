import QtQuick
import Quickshell
import qs.Commons
import qs.Services.UI

Item {
  id: root
  property var pluginApi: null

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  // Weekly limit data
  property int weeklyLimit: 0
  property int weeklyUsed: 0
  property int weeklyRemaining: 0
  property string weeklyResetTime: ""

  // 5-hour limit data
  property int fiveHourLimit: 0
  property int fiveHourUsed: 0
  property int fiveHourRemaining: 0
  property string fiveHourResetTime: ""

  property bool loading: false
  property string errorString: ""

  readonly property string apiKey: cfg.apiKey ?? defaults.apiKey ?? ""
  readonly property string apiEndpoint: cfg.apiEndpoint ?? defaults.apiEndpoint ?? "https://api.kimi.com/coding/v1/usages"

  Component.onCompleted: {
    Logger.i("KimiUsage", "Plugin loaded")
    refresh()
  }

  Timer {
    id: refreshTimer
    interval: 60000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  function refresh() {
    if (!apiKey || apiKey === "") {
      errorString = pluginApi?.tr("errors.noApiKey") || "No API key configured"
      return
    }

    loading = true
    errorString = ""

    let xhr = new XMLHttpRequest()
    xhr.open("GET", apiEndpoint)
    xhr.setRequestHeader("Authorization", "Bearer " + apiKey)
    xhr.setRequestHeader("Accept", "application/json")

    xhr.onreadystatechange = function() {
      if (xhr.readyState === XMLHttpRequest.DONE) {
        loading = false
        if (xhr.status === 200) {
          try {
            let data = JSON.parse(xhr.responseText)
            root.parseResponse(data)
          } catch (e) {
            errorString = pluginApi?.tr("errors.parse") || "Parse error"
            Logger.w("KimiUsage", "Failed to parse response: " + e)
          }
        } else if (xhr.status === 401) {
          errorString = pluginApi?.tr("errors.unauthorized") || "Unauthorized"
          Logger.w("KimiUsage", "HTTP 401: Invalid API key")
        } else if (xhr.status === 429) {
          errorString = pluginApi?.tr("errors.rateLimited") || "Rate limited"
          Logger.w("KimiUsage", "HTTP 429: Rate limited")
        } else {
          errorString = "HTTP " + xhr.status
          Logger.w("KimiUsage", "HTTP error " + xhr.status + ": " + xhr.responseText)
        }
      }
    }

    xhr.send()
  }

  function safeParseInt(val) {
    let n = parseInt(val)
    return isNaN(n) ? 0 : n
  }

  function parseResponse(data) {
    // Reset values
    weeklyLimit = 0
    weeklyUsed = 0
    weeklyRemaining = 0
    weeklyResetTime = ""
    fiveHourLimit = 0
    fiveHourUsed = 0
    fiveHourRemaining = 0
    fiveHourResetTime = ""

    Logger.d("KimiUsage", "Raw API response: " + JSON.stringify(data))

    // Try limits array first (Kimi Code format)
    if (data.limits && Array.isArray(data.limits)) {
      for (let i = 0; i < data.limits.length; i++) {
        let limit = data.limits[i]
        let window = limit.window || {}
        let detail = limit.detail || {}
        let duration = safeParseInt(window.duration)
        let timeUnit = window.timeUnit || ""

        Logger.d("KimiUsage", "Limit[" + i + "] duration=" + duration + " unit=" + timeUnit)

        // 5-hour limit = 300 minutes
        if (duration === 300 && timeUnit === "TIME_UNIT_MINUTE") {
          fiveHourLimit = safeParseInt(detail.limit)
          fiveHourUsed = safeParseInt(detail.used)
          fiveHourRemaining = safeParseInt(detail.remaining)
          if (fiveHourRemaining === 0 && fiveHourUsed > 0 && fiveHourLimit > 0) {
            fiveHourRemaining = fiveHourLimit - fiveHourUsed
          }
          fiveHourResetTime = detail.resetTime || ""
          Logger.d("KimiUsage", "Parsed 5h: used=" + fiveHourUsed + " remaining=" + fiveHourRemaining + " limit=" + fiveHourLimit)
        }

        // Weekly limit possibilities
        if ((duration === 10080 && timeUnit === "TIME_UNIT_MINUTE") ||
            timeUnit === "TIME_UNIT_WEEK" ||
            (duration === 7 && timeUnit === "TIME_UNIT_DAY") ||
            (duration === 168 && timeUnit === "TIME_UNIT_HOUR")) {
          weeklyLimit = safeParseInt(detail.limit)
          weeklyUsed = safeParseInt(detail.used)
          weeklyRemaining = safeParseInt(detail.remaining)
          if (weeklyRemaining === 0 && weeklyUsed > 0 && weeklyLimit > 0) {
            weeklyRemaining = weeklyLimit - weeklyUsed
          }
          weeklyResetTime = detail.resetTime || ""
          Logger.d("KimiUsage", "Parsed weekly from limits: used=" + weeklyUsed + " remaining=" + weeklyRemaining + " limit=" + weeklyLimit)
        }
      }
    }

    // If weekly not found in limits array, try data.usage as weekly fallback
    if (weeklyLimit === 0 && data.usage) {
      Logger.d("KimiUsage", "Using data.usage as weekly fallback")
      weeklyLimit = safeParseInt(data.usage.limit)
      weeklyUsed = safeParseInt(data.usage.used)
      weeklyRemaining = safeParseInt(data.usage.remaining)
      if (weeklyRemaining === 0 && weeklyUsed > 0 && weeklyLimit > 0) {
        weeklyRemaining = weeklyLimit - weeklyUsed
      }
      weeklyResetTime = data.usage.resetTime || ""
      Logger.d("KimiUsage", "Parsed weekly from usage: used=" + weeklyUsed + " remaining=" + weeklyRemaining + " limit=" + weeklyLimit)
    }

    Logger.i("KimiUsage", "Final weekly=" + weeklyRemaining + "/" + weeklyLimit + " (" + Math.round(weeklyLimit > 0 ? (weeklyRemaining / weeklyLimit) * 100 : 0) + "%), 5h=" + fiveHourRemaining + "/" + fiveHourLimit + " (" + Math.round(fiveHourLimit > 0 ? (fiveHourRemaining / fiveHourLimit) * 100 : 0) + "%)")
  }

  function formatResetTime(isoString) {
    if (!isoString) return ""
    try {
      let d = new Date(isoString)
      let now = new Date()
      let diffMs = d - now
      if (diffMs <= 0) return pluginApi?.tr("bar.soon") || "soon"
      let diffH = Math.floor(diffMs / 3600000)
      let diffM = Math.floor((diffMs % 3600000) / 60000)
      if (diffH > 0) {
        return diffH + "h " + diffM + "m"
      }
      return diffM + "m"
    } catch (e) {
      return ""
    }
  }

  function formatResetTimeHours(isoString) {
    if (!isoString) return ""
    try {
      let d = new Date(isoString)
      let now = new Date()
      let diffMs = d - now
      if (diffMs <= 0) return "0"
      let diffH = Math.round(diffMs / 3600000)
      return diffH.toString()
    } catch (e) {
      return ""
    }
  }
}
