package com.antidoom.services

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent

class AntiDoomAccessibilityService : AccessibilityService() {

    companion object {
        var instance: AntiDoomAccessibilityService? = null
            private set

        var isTrackingActive: Boolean = false
        var showFloatingCounter: Boolean = true
        var blocklist: Set<String> = setOf(
            "com.instagram.android",
            "com.zhiliaoapp.musically",
            "com.ss.android.ugc.trill",
            "com.google.android.youtube",
            "com.twitter.android",
            "com.facebook.katana"
        )

        var scrollThreshold: Int = 50
        var timeThresholdSeconds: Int = 900 // 15 mins
        var currentLanguage: String = "en" // English dominant default

        // In-memory stats for active session
        var currentActivePackage: String? = null
        var sessionScrollCount: Int = 0
        var sessionStartTime: Long = 0
        var isInterceptorShown: Boolean = false
        var snoozeUntilTime: Long = 0

        // Callbacks to notify MainActivity / Flutter
        var onScrollListener: ((packageName: String, scrollCount: Int) -> Unit)? = null
        var onLimitReachedListener: ((packageName: String, scrollCount: Int) -> Unit)? = null
    }

    private val handler = Handler(Looper.getMainLooper())
    private var lastScrollEventTime = 0L

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (!isTrackingActive || event == null) return

        val packageName = event.packageName?.toString() ?: return

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                handleWindowStateChanged(packageName)
            }
            AccessibilityEvent.TYPE_VIEW_SCROLLED -> {
                handleViewScrolled(packageName)
            }
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                // Throttle content changed events to act as secondary scroll detector
                val now = System.currentTimeMillis()
                if (now - lastScrollEventTime > 800 && isPackageBlocklisted(packageName)) {
                    lastScrollEventTime = now
                    handleViewScrolled(packageName)
                }
            }
        }
    }

    private fun handleWindowStateChanged(packageName: String) {
        if (packageName == this.packageName) {
            // User opened AntiDoom, do not count
            return
        }

        if (isPackageBlocklisted(packageName)) {
            if (currentActivePackage != packageName) {
                // Switched to a target app
                currentActivePackage = packageName
                sessionScrollCount = 0
                sessionStartTime = System.currentTimeMillis()
                isInterceptorShown = false

                if (showFloatingCounter) {
                    val readableName = getReadableAppName(packageName)
                    OverlayService.showCounter(this, readableName, sessionScrollCount, currentLanguage)
                }
            }
        } else {
            // User left target app
            if (currentActivePackage != null) {
                currentActivePackage = null
                if (showFloatingCounter) {
                    OverlayService.hideCounter(this)
                }
            }
        }
    }

    private fun handleViewScrolled(packageName: String) {
        if (!isPackageBlocklisted(packageName)) return

        val now = System.currentTimeMillis()
        if (now < snoozeUntilTime) {
            return // Currently in snooze
        }

        sessionScrollCount++
        lastScrollEventTime = now

        // Update floating counter bubble
        if (showFloatingCounter) {
            OverlayService.updateCounter(this, sessionScrollCount, currentLanguage)
        }

        // Notify Flutter listeners
        handler.post {
            onScrollListener?.invoke(packageName, sessionScrollCount)
        }

        // Check limits
        val elapsedSeconds = (now - sessionStartTime) / 1000
        val isScrollLimitReached = sessionScrollCount >= scrollThreshold
        val isTimeLimitReached = elapsedSeconds >= timeThresholdSeconds

        if ((isScrollLimitReached || isTimeLimitReached) && !isInterceptorShown) {
            isInterceptorShown = true
            val readableName = getReadableAppName(packageName)
            val message = if (currentLanguage == "id") {
                if (isScrollLimitReached) {
                    "Sudah mencapai batas $scrollThreshold scroll di $readableName. Istirahatkan pikiran sejenak yuk."
                } else {
                    "Sudah mencapai batas waktu ${timeThresholdSeconds / 60} menit di $readableName. Waktunya bernapas."
                }
            } else {
                if (isScrollLimitReached) {
                    "Reached the limit of $scrollThreshold scrolls on $readableName. Time to give your eyes a rest."
                } else {
                    "Reached the time limit of ${timeThresholdSeconds / 60} minutes on $readableName. Time to take a breath."
                }
            }

            OverlayService.showInterceptor(this, readableName, sessionScrollCount, message, currentLanguage)

            handler.post {
                onLimitReachedListener?.invoke(packageName, sessionScrollCount)
            }
        }
    }

    private fun isPackageBlocklisted(pkg: String): Boolean {
        return blocklist.contains(pkg)
    }

    private fun getReadableAppName(pkg: String): String {
        return when {
            pkg.contains("instagram") -> "Instagram"
            pkg.contains("musically") || pkg.contains("trill") -> "TikTok"
            pkg.contains("youtube") -> "YouTube Shorts"
            pkg.contains("twitter") -> "X (Twitter)"
            pkg.contains("katana") -> "Facebook"
            else -> pkg.substringAfterLast('.')
        }
    }

    fun snooze(minutes: Int = 5) {
        snoozeUntilTime = System.currentTimeMillis() + (minutes * 60 * 1000)
        isInterceptorShown = false
        OverlayService.dismissInterceptor(this)
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        OverlayService.hideCounter(this)
        OverlayService.dismissInterceptor(this)
    }
}
