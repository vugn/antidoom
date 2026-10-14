package com.antidoom

import android.os.Bundle
import com.antidoom.services.AntiDoomAccessibilityService
import com.antidoom.services.AntiDoomForegroundService
import com.antidoom.services.OverlayService
import com.antidoom.utils.PermissionHelper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.antidoom/native"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "startTracking" -> {
                        val blocklist = call.argument<List<String>>("blocklist")
                        val scrollLimit = call.argument<Int>("scrollLimit") ?: 50
                        val timeLimit = call.argument<Int>("timeLimit") ?: 900
                        val showFloating = call.argument<Boolean>("showFloatingCounter") ?: true
                        val language = call.argument<String>("language") ?: "en"

                        if (blocklist != null && blocklist.isNotEmpty()) {
                            AntiDoomAccessibilityService.blocklist = blocklist.toSet()
                        }
                        AntiDoomAccessibilityService.scrollThreshold = scrollLimit
                        AntiDoomAccessibilityService.timeThresholdSeconds = timeLimit
                        AntiDoomAccessibilityService.showFloatingCounter = showFloating
                        AntiDoomAccessibilityService.currentLanguage = language
                        AntiDoomAccessibilityService.isTrackingActive = true

                        // Start persistent foreground service
                        AntiDoomForegroundService.startService(this@MainActivity)

                        result.success(true)
                    }

                    "setLanguage" -> {
                        val language = call.argument<String>("language") ?: "en"
                        AntiDoomAccessibilityService.currentLanguage = language
                        result.success(true)
                    }

                    "stopTracking" -> {
                        AntiDoomAccessibilityService.isTrackingActive = false
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

                        OverlayService.showInterceptor(this@MainActivity, appName, scrollCount, message, language)
                        result.success(true)
                    }

                    "dismissOverlay" -> {
                        OverlayService.dismissInterceptor(this@MainActivity)
                        result.success(true)
                    }

                    "toggleFloatingCounter" -> {
                        val show = call.argument<Boolean>("show") ?: true
                        AntiDoomAccessibilityService.showFloatingCounter = show
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

                    "requestOverlayPermission" -> {
                        PermissionHelper.openOverlaySettings(this@MainActivity)
                        result.success(true)
                    }

                    "requestBatteryOptimization" -> {
                        PermissionHelper.requestIgnoreBatteryOptimization(this@MainActivity)
                        result.success(true)
                    }

                    "getNativeStats" -> {
                        val stats = mapOf(
                            "isTracking" to AntiDoomAccessibilityService.isTrackingActive,
                            "activePackage" to AntiDoomAccessibilityService.currentActivePackage,
                            "sessionScrollCount" to AntiDoomAccessibilityService.sessionScrollCount,
                            "scrollThreshold" to AntiDoomAccessibilityService.scrollThreshold,
                            "timeThresholdSeconds" to AntiDoomAccessibilityService.timeThresholdSeconds
                        )
                        result.success(stats)
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

    override fun onDestroy() {
        AntiDoomAccessibilityService.onScrollListener = null
        AntiDoomAccessibilityService.onLimitReachedListener = null
        super.onDestroy()
    }
}
