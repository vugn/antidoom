package com.antidoom

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.os.Bundle
import java.io.ByteArrayOutputStream
import com.antidoom.services.AntiDoomAccessibilityService
import com.antidoom.services.AntiDoomForegroundService
import com.antidoom.services.OverlayService
import com.antidoom.utils.PermissionHelper
import com.antidoom.utils.TrackerPrefs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.antidoom/native"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Restore persisted config in case the process was recreated
        // (the accessibility service may not have connected yet).
        if (!AntiDoomAccessibilityService.isTrackingActive) {
            AntiDoomAccessibilityService.loadConfig(applicationContext)
        }

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "startTracking" -> {
                        val svc = AntiDoomAccessibilityService
                        val blocklist = call.argument<List<String>>("blocklist")
                        val scrollLimit = call.argument<Int>("scrollLimit") ?: svc.scrollThreshold
                        val timeLimit = call.argument<Int>("timeLimit") ?: svc.timeThresholdSeconds
                        val showFloating = call.argument<Boolean>("showFloatingCounter") ?: svc.showFloatingCounter
                        val language = call.argument<String>("language") ?: svc.currentLanguage
                        // Config refreshes (rule toggled, limit changed) must NOT wipe the live counter
                        val resetSession = call.argument<Boolean>("resetSession") ?: true
                        val warnEvery = call.argument<Int>("warnEvery") ?: svc.warnEvery
                        val forceBlockAt = call.argument<Int>("forceBlockAt") ?: svc.forceBlockAt

                        // An empty list is valid: it means "monitor nothing"
                        if (blocklist != null) {
                            svc.blocklist = blocklist.toSet()
                        }
                        if (resetSession) svc.resetSession()
                        svc.scrollThreshold = scrollLimit
                        svc.timeThresholdSeconds = timeLimit
                        svc.showFloatingCounter = showFloating
                        svc.currentLanguage = language
                        svc.warnEvery = warnEvery
                        svc.forceBlockAt = forceBlockAt
                        svc.isTrackingActive = true
                        if (!showFloating) OverlayService.hideCounter(this@MainActivity)

                        // Persist so tracking survives process death / reboot
                        TrackerPrefs.saveConfig(
                            applicationContext, true, svc.blocklist,
                            scrollLimit, timeLimit, showFloating, language,
                            warnEvery, forceBlockAt
                        )

                        // Persistent foreground service (best effort)
                        try {
                            AntiDoomForegroundService.startService(this@MainActivity)
                        } catch (_: Exception) {}

                        result.success(true)
                    }

                    "setLanguage" -> {
                        val language = call.argument<String>("language") ?: "en"
                        AntiDoomAccessibilityService.currentLanguage = language
                        TrackerPrefs.setLanguage(applicationContext, language)
                        result.success(true)
                    }

                    "stopTracking" -> {
                        AntiDoomAccessibilityService.isTrackingActive = false
                        TrackerPrefs.setActive(applicationContext, false)
                        AntiDoomAccessibilityService.resetSession()
                        AntiDoomForegroundService.stopService(this@MainActivity)
                        OverlayService.hideCounter(this@MainActivity)
                        OverlayService.dismissInterceptor(this@MainActivity)
                        result.success(true)
                    }

                    "triggerOverlay" -> {
                        val appName = call.argument<String>("appName") ?: "Instagram"
                        val message = call.argument<String>("message") ?: "Time to take a mindful break from scrolling!"
                        val scrollCount = call.argument<Int>("scrollCount") ?: 50
                        val language = AntiDoomAccessibilityService.currentLanguage

                        // Overlays are drawn by the accessibility service; if it is
                        // not connected there is nothing to draw with.
                        val shown = OverlayService.showInterceptor(
                            this@MainActivity, scrollCount, 0, OverlayService.Mode.CHECK_IN, language
                        )
                        result.success(shown)
                    }

                    "dismissOverlay" -> {
                        OverlayService.dismissInterceptor(this@MainActivity)
                        result.success(true)
                    }

                    "toggleFloatingCounter" -> {
                        val show = call.argument<Boolean>("show") ?: true
                        AntiDoomAccessibilityService.showFloatingCounter = show
                        TrackerPrefs.setFloating(applicationContext, show)
                        if (!show) {
                            OverlayService.hideCounter(this@MainActivity)
                        }
                        result.success(true)
                    }

                    "checkPermissions" -> {
                        val status = PermissionHelper.getPermissionStatusMap(this@MainActivity)
                        result.success(status)
                    }

                    "requestAccessibilityPermission" -> {
                        PermissionHelper.openAccessibilitySettings(this@MainActivity)
                        result.success(true)
                    }


                    "requestBatteryOptimization" -> {
                        PermissionHelper.requestIgnoreBatteryOptimization(this@MainActivity)
                        result.success(true)
                    }

                    "getNativeStats" -> {
                        val stats = TrackerPrefs.loadStats(applicationContext)
                        val svc = AntiDoomAccessibilityService
                        result.success(
                            mapOf(
                                "isTracking" to svc.isTrackingActive,
                                "serviceConnected" to (svc.instance != null),
                                "activePackage" to svc.currentActivePackage,
                                "sessionScrollCount" to svc.sessionScrollCount,
                                "scrollThreshold" to svc.scrollThreshold,
                                "timeThresholdSeconds" to svc.timeThresholdSeconds,
                                "showFloatingCounter" to svc.showFloatingCounter,
                                "todayScrollCount" to stats.scrolls,
                                "todayInterventions" to stats.interventions,
                                "perAppScrolls" to stats.perApp,
                                "snoozedToday" to TrackerPrefs.isSnoozedToday(applicationContext)
                            )
                        )
                    }

                    "previewCounter" -> {
                        // Debug helper: show the floating counter for a few seconds
                        val count = call.argument<Int>("count") ?: 36
                        OverlayService.hideCounter(this@MainActivity)
                        OverlayService.showCounter(
                            this@MainActivity, "AntiDoom", count,
                            AntiDoomAccessibilityService.currentLanguage
                        )
                        android.os.Handler(mainLooper).postDelayed({
                            OverlayService.hideCounter(this@MainActivity)
                        }, 5000)
                        result.success(AntiDoomAccessibilityService.instance != null)
                    }

                    "openUrl" -> {
                        // Only our own https links (e.g. the GitHub repo) are opened.
                        val url = call.argument<String>("url") ?: ""
                        if (!url.startsWith("https://")) {
                            result.success(false)
                        } else {
                            try {
                                startActivity(
                                    android.content.Intent(
                                        android.content.Intent.ACTION_VIEW,
                                        android.net.Uri.parse(url)
                                    ).addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                                )
                                result.success(true)
                            } catch (_: Exception) {
                                result.success(false)
                            }
                        }
                    }

                    "clearSnooze" -> {
                        TrackerPrefs.clearSnooze(applicationContext)
                        result.success(true)
                    }

                    "getAppInfo" -> {
                        // Real label + launcher icon (PNG) for each installed package.
                        // Packages that are not installed are simply omitted.
                        val pkgs = call.argument<List<String>>("packages") ?: emptyList()
                        Thread {
                            val out = HashMap<String, Any>()
                            for (pkg in pkgs) {
                                try {
                                    val ai = packageManager.getApplicationInfo(pkg, 0)
                                    out[pkg] = mapOf(
                                        "label" to packageManager.getApplicationLabel(ai).toString(),
                                        "icon" to drawableToPng(packageManager.getApplicationIcon(ai), 144)
                                    )
                                } catch (_: Exception) {}
                            }
                            runOnUiThread { result.success(out) }
                        }.start()
                    }

                    else -> result.notImplemented()
                }
            }
        }

        // Connect native accessibility events to Flutter MethodChannel
        AntiDoomAccessibilityService.onScrollListener = { packageName, scrollCount ->
            runOnUiThread {
                methodChannel?.invokeMethod(
                    "onScrollDetected",
                    mapOf("package" to packageName, "scrollCount" to scrollCount)
                )
            }
        }

        AntiDoomAccessibilityService.onLimitReachedListener = { packageName, scrollCount ->
            runOnUiThread {
                methodChannel?.invokeMethod(
                    "onLimitReached",
                    mapOf("package" to packageName, "scrollCount" to scrollCount)
                )
            }
        }
    }

    private fun drawableToPng(d: Drawable, size: Int): ByteArray {
        val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        d.setBounds(0, 0, size, size)
        d.draw(canvas)
        val bos = ByteArrayOutputStream()
        bmp.compress(Bitmap.CompressFormat.PNG, 100, bos)
        return bos.toByteArray()
    }

    override fun onDestroy() {
        AntiDoomAccessibilityService.onScrollListener = null
        AntiDoomAccessibilityService.onLimitReachedListener = null
        super.onDestroy()
    }
}
