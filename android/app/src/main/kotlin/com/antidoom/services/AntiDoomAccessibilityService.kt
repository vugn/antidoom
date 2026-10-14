package com.antidoom.services

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

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

        // Active screen state detection (whether currently in Shorts/Reels/FYP)
        var isCurrentlyInTargetMode: Boolean = false
        var currentTargetModeName: String? = null

        // Callbacks to notify MainActivity / Flutter
        var onScrollListener: ((packageName: String, scrollCount: Int) -> Unit)? = null
        var onLimitReachedListener: ((packageName: String, scrollCount: Int) -> Unit)? = null

        // Cooldown between swipe gestures (800ms coalesces fling & snap frames into 1 count)
        private const val SCROLL_DEBOUNCE_MS = 800L
        private const val APP_SWITCH_GRACE_PERIOD_MS = 600L
    }

    private val handler = Handler(Looper.getMainLooper())
    private var lastCountedScrollTime = 0L
    private var appSwitchTime = 0L
    private var isScreenReceiverRegistered = false

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    // Screen turned off / locked: Hide overlay immediately
                    if (showFloatingCounter) {
                        OverlayService.hideCounter(this@AntiDoomAccessibilityService)
                    }
                    OverlayService.dismissInterceptor(this@AntiDoomAccessibilityService)
                }
                Intent.ACTION_USER_PRESENT -> {
                    // Phone unlocked: Check if user is currently inside a monitored feed
                    handler.postDelayed({
                        val activePkg = rootInActiveWindow?.packageName?.toString() ?: currentActivePackage
                        if (activePkg != null && isPackageBlocklisted(activePkg)) {
                            updateScreenContext(activePkg, null)
                        }
                    }, 400)
                }
            }
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this

        if (!isScreenReceiverRegistered) {
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_OFF)
                addAction(Intent.ACTION_USER_PRESENT)
            }
            registerReceiver(screenReceiver, filter)
            isScreenReceiverRegistered = true
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (!isTrackingActive || event == null) return

        val packageName = event.packageName?.toString() ?: return

        // 1. If user switched to Home launcher or any regular non-blocklisted app:
        if (isLauncherPackage(packageName) || (!isPackageBlocklisted(packageName) && !isSystemOverlayPackage(packageName))) {
            if (currentActivePackage != null || isCurrentlyInTargetMode) {
                currentActivePackage = null
                isCurrentlyInTargetMode = false
                currentTargetModeName = null
                if (showFloatingCounter) {
                    OverlayService.hideCounter(this)
                }
            }
            return
        }

        // 2. Ignore AntiDoom app itself
        if (packageName == this.packageName) {
            if (isCurrentlyInTargetMode) {
                isCurrentlyInTargetMode = false
                currentTargetModeName = null
                if (showFloatingCounter) {
                    OverlayService.hideCounter(this)
                }
            }
            return
        }

        // 3. Handle blocklisted app events
        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
            AccessibilityEvent.TYPE_WINDOWS_CHANGED -> {
                handleWindowStateChanged(packageName, event)
            }
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                // DO NOT count scrolls on content changes!
                // Only inspect screen mode (e.g. user entered or left Shorts/Reels tab)
                if (isPackageBlocklisted(packageName)) {
                    updateScreenContext(packageName, event)
                }
            }
            AccessibilityEvent.TYPE_VIEW_SCROLLED -> {
                // ONLY handle VIEW_SCROLLED (do not use VIEW_SELECTED to avoid idle phantom scrolls)
                handleViewScrolled(packageName, event)
            }
        }
    }

    private fun handleWindowStateChanged(packageName: String, event: AccessibilityEvent?) {
        if (isPackageBlocklisted(packageName)) {
            val now = System.currentTimeMillis()
            if (currentActivePackage != packageName) {
                // Switching between different blocklisted apps (e.g. Instagram -> YouTube)
                if (showFloatingCounter) {
                    OverlayService.hideCounter(this)
                }
                currentActivePackage = packageName
                sessionStartTime = now
                appSwitchTime = now
                isInterceptorShown = false
                isCurrentlyInTargetMode = false
                lastCountedScrollTime = 0L
            }
            updateScreenContext(packageName, event)
        } else if (!isSystemOverlayPackage(packageName)) {
            // Left blocklisted app
            if (currentActivePackage != null || isCurrentlyInTargetMode) {
                currentActivePackage = null
                isCurrentlyInTargetMode = false
                currentTargetModeName = null
                if (showFloatingCounter) {
                    OverlayService.hideCounter(this)
                }
            }
        }
    }

    private fun updateScreenContext(packageName: String, event: AccessibilityEvent?) {
        if (!isPackageBlocklisted(packageName) || !isTrackingActive) {
            if (isCurrentlyInTargetMode) {
                isCurrentlyInTargetMode = false
                currentTargetModeName = null
                if (showFloatingCounter) {
                    OverlayService.hideCounter(this)
                }
            }
            return
        }

        val inTarget = isTargetShortVideoMode(packageName, event)

        if (inTarget && !isCurrentlyInTargetMode) {
            // User entered targeted short video mode (e.g. opened YouTube Shorts or Instagram Reels)
            isCurrentlyInTargetMode = true
            currentTargetModeName = getReadableTargetName(packageName)
            if (showFloatingCounter) {
                OverlayService.showCounter(this, "AntiDoom", sessionScrollCount, currentLanguage)
            }
        } else if (!inTarget && isCurrentlyInTargetMode) {
            // User might have left short video mode (e.g. navigated back to Home/Beranda or Search)
            // BUT: only exit target mode if we have positive confirmation they left (e.g. Home feed detected),
            // NOT when rootInActiveWindow is temporarily null or unreadable during touch/video loading!
            if (isConfirmedOutsideShortVideo(packageName)) {
                isCurrentlyInTargetMode = false
                currentTargetModeName = null
                if (showFloatingCounter) {
                    OverlayService.hideCounter(this)
                }
            }
        }
    }

    private fun handleViewScrolled(packageName: String, event: AccessibilityEvent?) {
        if (!isPackageBlocklisted(packageName) || !isTrackingActive) return

        val now = System.currentTimeMillis()

        // 1. Check snooze
        if (now < snoozeUntilTime) return

        // 2. Ignore initial switch window (600ms) to avoid cold-start inflation spikes
        if (now - appSwitchTime < APP_SWITCH_GRACE_PERIOD_MS) {
            return
        }

        // 3. Verify target short-video mode:
        // If not already marked as in target mode, check if this event itself indicates entering Shorts/Reels
        if (!isCurrentlyInTargetMode) {
            if (isTargetShortVideoMode(packageName, event)) {
                isCurrentlyInTargetMode = true
                currentTargetModeName = getReadableTargetName(packageName)
                if (showFloatingCounter) {
                    OverlayService.showCounter(this, "AntiDoom", sessionScrollCount, currentLanguage)
                }
            } else {
                // Outside short-video mode (e.g. regular YouTube Home/Beranda) -> Ignore scroll!
                return
            }
        }

        // 4. Do not count comment section or chat scrolling as video swipes
        val sourceRes = event?.source?.viewIdResourceName?.lowercase() ?: ""
        if (sourceRes.contains("comment") || sourceRes.contains("chat") || sourceRes.contains("direct")) {
            return
        }

        // 5. Direction validation: Short-form video feeds are strictly VERTICAL
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P && event != null) {
            val dx = Math.abs(event.scrollDeltaX)
            val dy = Math.abs(event.scrollDeltaY)

            // Horizontal swipe (switching tabs, audio carousels, chips) -> ignore!
            if (dx > 40 && dx > dy * 2) {
                return
            }
        }

        // 6. Enforce debounce cooldown:
        // 800ms coalesces drag, release, fling inertia, and snapping frames of ONE physical swipe into 1 count
        if (now - lastCountedScrollTime < SCROLL_DEBOUNCE_MS) {
            return
        }

        // Genuine video swipe confirmed!
        lastCountedScrollTime = now
        sessionScrollCount++

        // Update floating counter bubble immediately (general AntiDoom tracker)
        if (showFloatingCounter) {
            OverlayService.updateCounter(this, sessionScrollCount, currentLanguage, "AntiDoom")
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
            val message = if (currentLanguage == "id") {
                if (isScrollLimitReached) {
                    "Sudah mencapai batas $scrollThreshold scroll. Istirahatkan pikiran sejenak yuk."
                } else {
                    "Sudah mencapai batas waktu ${timeThresholdSeconds / 60} menit. Waktunya bernapas."
                }
            } else {
                if (isScrollLimitReached) {
                    "Reached the limit of $scrollThreshold scrolls. Time to give your eyes a rest."
                } else {
                    "Reached the time limit of ${timeThresholdSeconds / 60} minutes. Time to take a breath."
                }
            }

            OverlayService.showInterceptor(this, "AntiDoom", sessionScrollCount, message, currentLanguage)

            handler.post {
                onLimitReachedListener?.invoke(packageName, sessionScrollCount)
            }
        }
    }

    private fun isTargetShortVideoMode(packageName: String, event: AccessibilityEvent?): Boolean {
        return when (packageName) {
            "com.google.android.youtube" -> isYouTubeShorts(event)
            "com.instagram.android" -> isInstagramReels(event)
            "com.facebook.katana" -> isFacebookReels(event)
            "com.zhiliaoapp.musically", "com.ss.android.ugc.trill" -> isTikTokVideoFeed(event)
            "com.twitter.android" -> true // Twitter timeline
            else -> true
        }
    }

    private fun isConfirmedOutsideShortVideo(packageName: String): Boolean {
        val root = rootInActiveWindow ?: return false // If root is null during fling, do not assume left!

        return when (packageName) {
            "com.google.android.youtube" -> {
                // Check if Home or Subscriptions tab is selected
                val homeTabs = root.findAccessibilityNodeInfosByText("Home") +
                        root.findAccessibilityNodeInfosByText("Beranda")
                val isHomeTabSelected = homeTabs.any { it.isSelected || (it.parent?.isSelected == true) }

                val subsTabs = root.findAccessibilityNodeInfosByText("Subscriptions") +
                        root.findAccessibilityNodeInfosByText("Subscription") +
                        root.findAccessibilityNodeInfosByText("Koleksi")
                val isSubsTabSelected = subsTabs.any { it.isSelected || (it.parent?.isSelected == true) }

                val filterNodes = root.findAccessibilityNodeInfosByViewId("com.google.android.youtube:id/feed_filter_bar")
                val isFilterBarVisible = filterNodes.any { it.isVisibleToUser }

                (isHomeTabSelected || isSubsTabSelected || isFilterBarVisible) && !isYouTubeShorts(null)
            }
            "com.instagram.android" -> {
                val mainFeedNodes = root.findAccessibilityNodeInfosByViewId("com.instagram.android:id/main_feed") +
                        root.findAccessibilityNodeInfosByViewId("com.instagram.android:id/feed_recycler_view")
                val hasVisibleMainFeed = mainFeedNodes.any { it.isVisibleToUser }
                hasVisibleMainFeed && !isInstagramReels(null)
            }
            "com.facebook.katana" -> {
                val hasReels = !root.findAccessibilityNodeInfosByViewId("com.facebook.katana:id/reel_viewer").isNullOrEmpty() ||
                        !root.findAccessibilityNodeInfosByViewId("com.facebook.katana:id/fb_shorts").isNullOrEmpty()
                !hasReels
            }
            else -> false
        }
    }

    private fun isYouTubeShorts(event: AccessibilityEvent?): Boolean {
        // 1. Direct event check (viewId, className, contentDescription)
        val sourceRes = event?.source?.viewIdResourceName?.lowercase() ?: ""
        if ((sourceRes.contains("shorts") || sourceRes.contains("reel")) && !sourceRes.contains("shorts_shelf")) {
            return true
        }

        val className = event?.className?.toString()?.lowercase() ?: ""
        if (className.contains("reel") || className.contains("shorts")) {
            return true
        }

        // 2. Active Window Hierarchy check
        val root = rootInActiveWindow ?: return false

        // Check if "Shorts" tab in bottom navigation is selected
        val shortsTabs = root.findAccessibilityNodeInfosByText("Shorts")
        if (shortsTabs.any { it.isSelected || (it.parent?.isSelected == true) }) {
            return true
        }

        val shortsViewIds = listOf(
            "com.google.android.youtube:id/reel_recycler",
            "com.google.android.youtube:id/shorts_container",
            "com.google.android.youtube:id/reel_player_page_view",
            "com.google.android.youtube:id/reel_player",
            "com.google.android.youtube:id/reel_view_holder",
            "com.google.android.youtube:id/shorts_video_player",
            "com.google.android.youtube:id/shorts_player",
            "com.google.android.youtube:id/reel_watch_fragment",
            "com.google.android.youtube:id/reel_swipe_indicator",
            "com.google.android.youtube:id/pivot_button",
            "com.google.android.youtube:id/reel_feed_layout"
        )
        for (id in shortsViewIds) {
            try {
                val nodes = root.findAccessibilityNodeInfosByViewId(id)
                if (nodes.any { it.isVisibleToUser }) {
                    return true
                }
            } catch (_: Exception) {}
        }

        // 3. Check for Shorts specific action keywords in both Indonesian and English
        val shortsKeywords = listOf(
            "remix",
            "sound used",
            "dislike this short",
            "tidak suka video short",
            "suka video short",
            "gunakan suara",
            "audio asli"
        )
        for (kw in shortsKeywords) {
            try {
                val nodes = root.findAccessibilityNodeInfosByText(kw)
                if (nodes.any { it.isVisibleToUser }) {
                    return true
                }
            } catch (_: Exception) {}
        }

        return false
    }

    private fun isInstagramReels(event: AccessibilityEvent?): Boolean {
        val sourceRes = event?.source?.viewIdResourceName?.lowercase() ?: ""
        if (sourceRes.contains("clips") || sourceRes.contains("reel_viewer")) {
            return true
        }

        val className = event?.className?.toString()?.lowercase() ?: ""
        if (className.contains("clips") || className.contains("reel")) {
            return true
        }

        val root = rootInActiveWindow ?: return false
        val reelsViewIds = listOf(
            "com.instagram.android:id/clips_viewer_view_pager",
            "com.instagram.android:id/clips_video_container",
            "com.instagram.android:id/clips_item_container",
            "com.instagram.android:id/reel_viewer",
            "com.instagram.android:id/clips_swipe_refresh_container",
            "com.instagram.android:id/clips_root_container",
            "com.instagram.android:id/clips_gesture_view"
        )
        for (id in reelsViewIds) {
            try {
                val nodes = root.findAccessibilityNodeInfosByViewId(id)
                if (nodes.any { it.isVisibleToUser }) {
                    return true
                }
            } catch (_: Exception) {}
        }

        return false
    }

    private fun isTikTokVideoFeed(event: AccessibilityEvent?): Boolean {
        val sourceRes = event?.source?.viewIdResourceName?.lowercase() ?: ""
        if (sourceRes.contains("comment") ||
            sourceRes.contains("profile") ||
            sourceRes.contains("search") ||
            sourceRes.contains("message") ||
            sourceRes.contains("chat")
        ) {
            return false
        }

        val root = rootInActiveWindow ?: return true
        val commentIds = listOf(
            "com.zhiliaoapp.musically:id/comment_list",
            "com.zhiliaoapp.musically:id/comment_container",
            "com.ss.android.ugc.trill:id/comment_list",
            "com.ss.android.ugc.trill:id/comment_container"
        )
        for (id in commentIds) {
            try {
                val nodes = root.findAccessibilityNodeInfosByViewId(id)
                if (!nodes.isNullOrEmpty()) {
                    return false
                }
            } catch (_: Exception) {}
        }
        return true
    }

    private fun isFacebookReels(event: AccessibilityEvent?): Boolean {
        val sourceRes = event?.source?.viewIdResourceName?.lowercase() ?: ""
        if (sourceRes.contains("fb_shorts") ||
            sourceRes.contains("reel_viewer") ||
            sourceRes.contains("short_video") ||
            sourceRes.contains("reels_tray")
        ) {
            return true
        }

        val root = rootInActiveWindow ?: return false
        val reelsIds = listOf(
            "com.facebook.katana:id/reel_viewer",
            "com.facebook.katana:id/fb_shorts"
        )
        for (id in reelsIds) {
            try {
                val nodes = root.findAccessibilityNodeInfosByViewId(id)
                if (nodes.any { it.isVisibleToUser }) {
                    return true
                }
            } catch (_: Exception) {}
        }
        return false
    }

    private fun isLauncherPackage(pkg: String): Boolean {
        val lower = pkg.lowercase()
        return lower.contains("launcher") ||
                lower.contains("quickstep") ||
                lower.contains(".home") ||
                lower == "com.android.launcher" ||
                lower == "com.google.android.apps.nexuslauncher" ||
                lower == "com.sec.android.app.launcher" ||
                lower == "com.miui.home" ||
                lower == "com.huawei.android.launcher" ||
                lower == "com.oppo.launcher" ||
                lower == "com.transsion.hilauncher"
    }

    private fun isSystemOverlayPackage(pkg: String): Boolean {
        val lower = pkg.lowercase()
        return lower == "com.android.systemui" ||
                lower.contains("inputmethod") ||
                lower.contains("keyboard") ||
                lower.contains("ime")
    }

    private fun isPackageBlocklisted(pkg: String): Boolean {
        return blocklist.contains(pkg)
    }

    private fun getReadableTargetName(pkg: String): String {
        return when {
            pkg.contains("youtube") -> "YouTube Shorts"
            pkg.contains("instagram") -> "Instagram Reels"
            pkg.contains("musically") || pkg.contains("trill") -> "TikTok"
            pkg.contains("twitter") -> "X (Twitter)"
            pkg.contains("katana") -> "Facebook Reels"
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
        if (isScreenReceiverRegistered) {
            try {
                unregisterReceiver(screenReceiver)
            } catch (_: Exception) {}
            isScreenReceiverRegistered = false
        }
        OverlayService.hideCounter(this)
        OverlayService.dismissInterceptor(this)
    }
}
