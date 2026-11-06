package com.antidoom.services

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import com.antidoom.utils.TrackerPrefs
import java.util.ArrayDeque

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
        /** Check-in every N swipes today (0 = off). */
        var warnEvery: Int = 100
        /** Hard block once today's swipes reach N (0 = off). */
        var forceBlockAt: Int = 0
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

        // One physical swipe = one continuous burst of scroll events (drag frames,
        // release, fling inertia, snap). A quiet gap (> GESTURE_GAP_MS) between
        // events marks the start of a NEW swipe, so a slow drag + its settle
        // animation are never counted as 2 swipes.
        private const val GESTURE_GAP_MS = 500L
        // Entering Reels/Shorts/FYP plays a ViewPager slide-in animation that emits
        // TYPE_VIEW_SCROLLED events - ignore them so opening the feed is never counted.
        private const val TARGET_MODE_ENTRY_GRACE_MS = 1000L
        private const val APP_SWITCH_GRACE_PERIOD_MS = 600L

        // Fingerprint counting: a video counts once its fingerprint has been on
        // screen this long (quick flicks past a video don't count).
        private const val DWELL_MS = 750L
        // Throttle for screen reads while in a feed (events arrive constantly).
        private const val SCAN_DELAY_MS = 250L
        // How many recent videos to remember so scrolling back doesn't recount.
        private const val RECENT_KEYS = 40
        private const val TAG = "AntiDoomDetect"
        // How long the screen must keep reading "not a feed" before the counter hides.
        private const val EXIT_CHECK_DELAY_MS = 700L

        /**
         * Resets the unified session: scroll counter, timer, interceptor flag and
         * gesture tracking. The session is shared by ALL monitored social apps, so
         * it only resets when the user leaves social media entirely, snoozes, or
         * (re)starts tracking - never when switching between social apps.
         */
        /**
         * Restores tracking config from persistent storage. Called when the
         * service connects (after process death / reboot) and when MainActivity
         * starts, so the in-memory statics never fall back to stale defaults.
         */
        fun loadConfig(context: Context) {
            val cfg = TrackerPrefs.loadConfig(context)
            cfg.blocklist?.let { blocklist = it }
            scrollThreshold = cfg.scrollLimit
            timeThresholdSeconds = cfg.timeLimitSeconds
            warnEvery = cfg.warnEvery
            forceBlockAt = cfg.forceBlockAt
            showFloatingCounter = cfg.showFloating
            currentLanguage = cfg.language
            isTrackingActive = cfg.trackingActive
        }

        fun resetSession() {
            sessionScrollCount = 0
            sessionStartTime = 0L
            isInterceptorShown = false
            instance?.resetGestureTracking()
        }
    }

    private val handler = Handler(Looper.getMainLooper())

    // Gesture-based swipe tracking (coalesces one physical swipe into 1 count)
    private var lastScrollEventTime = 0L
    private var gestureCounted = false
    private var targetModeEnterTime = 0L

    private var appSwitchTime = 0L
    private var isScreenReceiverRegistered = false

    // ---- Fingerprint (distinct-video) tracking ----
    /** Fingerprint currently on screen and since when (for the dwell check). */
    private var observedKey: String? = null
    private var observedSince = 0L
    /** Last video we counted, plus a short history to ignore revisits. */
    private var lastCountedKey: String? = null
    private val recentKeys = ArrayDeque<String>()
    /** Set once the detector produced a fingerprint in this app; until then
     *  the old scroll-gesture counting is used as a fallback. */
    private val fingerprintPkgs = HashSet<String>()
    private var scanScheduled = false
    private val scanRunnable = Runnable {
        scanScheduled = false
        scanCurrentReel()
    }

    /**
     * Leaving the feed (profile, DMs, search, account switcher...): the screen
     * read "not a video feed" once, so re-read it shortly after and hide the
     * counter if it still isn't. One read alone is not enough: while a video
     * loads or during a fling the feed can briefly look empty.
     */
    private var exitCheckPkg: String? = null
    private val exitCheckRunnable = Runnable {
        val pkg = exitCheckPkg ?: return@Runnable
        exitCheckPkg = null
        // Only the feed state matters here, not currentActivePackage: a stray
        // window event from another package can clear that while we're still
        // in the app, and the counter would then never hide.
        if (!isCurrentlyInTargetMode) {
            if (isDebuggable) Log.d(TAG, "exit check [$pkg]: already left")
            return@Runnable
        }
        val root = findRoot(pkg) ?: run {
            if (isDebuggable) Log.d(TAG, "exit check [$pkg]: screen unreadable, keep counter")
            return@Runnable
        }
        val still = isTargetShortVideoMode(pkg, null, root)
        if (isDebuggable) Log.d(TAG, "exit check [$pkg]: still in feed=$still")
        if (still) return@Runnable
        leaveTargetMode()
    }

    private fun scheduleExitCheck(pkg: String) {
        if (exitCheckPkg == pkg) return
        exitCheckPkg = pkg
        handler.postDelayed(exitCheckRunnable, EXIT_CHECK_DELAY_MS)
    }

    private fun cancelExitCheck() {
        exitCheckPkg = null
        handler.removeCallbacks(exitCheckRunnable)
    }

    private fun leaveTargetMode() {
        cancelExitCheck()
        isCurrentlyInTargetMode = false
        currentTargetModeName = null
        if (showFloatingCounter) OverlayService.hideCounter(this)
    }
    private val isDebuggable by lazy {
        (applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0
    }

    private fun resetGestureTracking() {
        lastScrollEventTime = 0L
        gestureCounted = false
        observedKey = null
        observedSince = 0L
    }

    private fun fingerprintActive(pkg: String) =
        pkg in fingerprintPkgs && ReelDetector.supports(pkg)

    /** Package the pending scan is for (taken from the triggering event). */
    private var scanPkg: String? = null

    private fun requestScan(delay: Long = SCAN_DELAY_MS, pkg: String? = null) {
        if (pkg != null) scanPkg = pkg
        if (scanScheduled) return
        scanScheduled = true
        handler.postDelayed(scanRunnable, delay)
    }

    /** One-off synchronous read: can the detector see this feed right now? */
    private fun canFingerprintNow(pkg: String): Boolean {
        val root = findRoot(pkg) ?: return false
        val dm = resources.displayMetrics
        return try {
            ReelDetector.detect(root, pkg, dm.widthPixels, dm.heightPixels) !is ReelDetector.Result.NoKey
        } catch (_: Exception) {
            false
        }
    }

    /** Root of the app's own window (our overlay windows can be "active"). */
    private fun findRoot(pkg: String): AccessibilityNodeInfo? = try {
        rootInActiveWindow?.takeIf { it.packageName?.toString() == pkg }
            ?: windows.firstNotNullOfOrNull { w ->
                w.root?.takeIf { it.packageName?.toString() == pkg }
            }
    } catch (_: Exception) {
        null
    }

    /** Reads the screen, and counts a video once a NEW fingerprint has settled. */
    private fun scanCurrentReel() {
        val pkg = scanPkg ?: currentActivePackage ?: return
        if (!isTrackingActive || !isCurrentlyInTargetMode || !ReelDetector.supports(pkg)) {
            if (isDebuggable) Log.v(TAG, "skip scan pkg=$pkg active=$isTrackingActive feed=$isCurrentlyInTargetMode")
            return
        }
        val root = findRoot(pkg) ?: run {
            if (isDebuggable) Log.v(TAG, "no root for $pkg")
            return
        }

        val dm = resources.displayMetrics
        val result = try {
            ReelDetector.detect(root, pkg, dm.widthPixels, dm.heightPixels)
        } catch (e: Exception) {
            Log.w(TAG, "detect failed", e)
            return
        }
        if (isDebuggable) Log.v(TAG, "scan [$pkg]: $result")
        val reel = result as? ReelDetector.Result.Reel
            ?: return // paused (comments open) or nothing readable yet
        val key = reel.key
        fingerprintPkgs.add(pkg)

        val now = System.currentTimeMillis()
        if (key != observedKey) {
            observedKey = key
            observedSince = now
            // Re-check once the dwell time has passed.
            handler.removeCallbacks(scanRunnable)
            scanScheduled = false
            requestScan(DWELL_MS + 50)
            return
        }
        if (now - observedSince < DWELL_MS) {
            requestScan(DWELL_MS - (now - observedSince) + 50)
            return
        }

        val last = lastCountedKey
        if (last != null && ReelDetector.sameReel(last, key)) {
            lastCountedKey = key // same video, text just finished loading
            return
        }
        if (recentKeys.any { ReelDetector.sameReel(it, key) }) {
            lastCountedKey = key // scrolled back to a video we already counted
            if (isDebuggable) Log.d(TAG, "revisit, not counted: ${reel.label}")
            return
        }
        lastCountedKey = key
        recentKeys.addLast(key)
        while (recentKeys.size > RECENT_KEYS) recentKeys.removeFirst()
        TrackerPrefs.saveRecentReels(applicationContext, recentKeys)
        if (isDebuggable) Log.d(TAG, "counted [$pkg]: ${reel.label}")
        countReel(pkg, now)
    }

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    // Screen turned off / locked: Hide overlay immediately
                    if (showFloatingCounter) {
                        OverlayService.hideCounter(this@AntiDoomAccessibilityService)
                    }
                    OverlayService.dismissInterceptor(this@AntiDoomAccessibilityService)
                    // The interceptor was removed without a user decision: allow it
                    // to show again on the next over-limit swipe.
                    isInterceptorShown = false
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
        loadConfig(applicationContext)
        recentKeys.clear()
        recentKeys.addAll(TrackerPrefs.loadRecentReels(applicationContext))
        lastCountedKey = recentKeys.lastOrNull()

        // The system rebinds us after the app was killed, a reboot, or (on vendor
        // ROMs) an auto-start. Bring the foreground service back with us; a bound
        // accessibility service is allowed to start one from the background.
        if (isTrackingActive) {
            try {
                AntiDoomForegroundService.startService(applicationContext)
            } catch (_: Exception) {}
        }

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

        // 1. Ignore events from our own app package COMPLETELY. Our floating
        // counter & interceptor are overlay WINDOWS of this package (see
        // flagRetrieveInteractiveWindows): reacting to them would constantly
        // kill & restart target mode (flickering counter) and refresh the
        // entry grace (scrolls never counted).
        if (packageName == this.packageName) return

        if (isPackageBlocklisted(packageName)) {
            // 2. Monitored social media app events
            when (event.eventType) {
                AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
                AccessibilityEvent.TYPE_WINDOWS_CHANGED -> {
                    handleWindowStateChanged(packageName, event)
                }
                AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                    // DO NOT count scrolls on content changes!
                    // Only inspect screen mode (e.g. user entered or left Shorts/Reels tab)
                    updateScreenContext(packageName, event)
                }
                AccessibilityEvent.TYPE_VIEW_SCROLLED -> {
                    // ONLY handle VIEW_SCROLLED (do not use VIEW_SELECTED to avoid idle phantom scrolls)
                    handleViewScrolled(packageName, event)
                }
            }
            // Any change in the feed may mean a new video: read the screen (throttled).
            if (isCurrentlyInTargetMode && ReelDetector.supports(packageName)) {
                requestScan(pkg = packageName)
            }
        } else if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            // 3. Only a REAL foreground window switch (launcher, system UI, or
            // any other app) ends the unified session. Stray content/scroll
            // events and background-window changes from foreign packages
            // (heads-up notifications, chat heads, widgets) must NOT disturb it.
            handleWindowStateChanged(packageName, event)
        }
    }

    private fun handleWindowStateChanged(packageName: String, event: AccessibilityEvent?) {
        if (isPackageBlocklisted(packageName)) {
            val now = System.currentTimeMillis()
            if (currentActivePackage != packageName) {
                if (currentActivePackage == null) {
                    // Entering social media from outside: start a fresh unified session
                    resetSession()
                    sessionStartTime = now
                } else if (showFloatingCounter) {
                    // Switching between monitored social apps (e.g. Instagram -> TikTok):
                    // the unified counter KEEPS counting (no escaping the limit by
                    // hopping between apps). Only refresh the entry grace period.
                    OverlayService.hideCounter(this)
                }
                currentActivePackage = packageName
                appSwitchTime = now
                isCurrentlyInTargetMode = false
                resetGestureTracking()
            }
            updateScreenContext(packageName, event)
        } else if (!isSystemOverlayPackage(packageName)) {
            // Left all monitored social media entirely -> end the unified session
            if (currentActivePackage != null || isCurrentlyInTargetMode) {
                resetSession()
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
        if (inTarget) cancelExitCheck()

        if (inTarget && !isCurrentlyInTargetMode) {
            // User entered targeted short video mode (e.g. opened YouTube Shorts or Instagram Reels)
            if (currentActivePackage == null) currentActivePackage = packageName
            isCurrentlyInTargetMode = true
            currentTargetModeName = getReadableTargetName(packageName)
            // Entry grace: the Reels/Shorts slide-in animation emits scroll events
            // that must NOT be counted as swipes.
            targetModeEnterTime = System.currentTimeMillis()
            resetGestureTracking()
            if (showFloatingCounter) {
                OverlayService.showCounter(this, "AntiDoom", todayCount(), currentLanguage)
            }
            // Already over the hard limit: block as soon as the feed opens
            if (isBlockedToday()) showBlock()
        } else if (!inTarget && isCurrentlyInTargetMode) {
            // Probably left the feed (home, profile, DMs, search, account switcher).
            // A known home screen hides the counter right away; anything else is
            // re-checked shortly, so a loading video never makes it flicker.
            if (isConfirmedOutsideShortVideo(packageName)) {
                if (isDebuggable) Log.d(TAG, "left feed [$packageName]: home screen")
                leaveTargetMode()
            } else {
                if (isDebuggable) Log.v(TAG, "maybe left feed [$packageName]: re-check")
                scheduleExitCheck(packageName)
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
                if (currentActivePackage == null) currentActivePackage = packageName
                isCurrentlyInTargetMode = true
                currentTargetModeName = getReadableTargetName(packageName)
                targetModeEnterTime = now
                resetGestureTracking()
                if (showFloatingCounter) {
                    OverlayService.showCounter(this, "AntiDoom", todayCount(), currentLanguage)
                }
                if (isBlockedToday()) {
                    showBlock()
                    return
                }
            } else {
                // Outside short-video mode (e.g. regular YouTube Home/Beranda) -> Ignore scroll!
                return
            }
        }

        // 3b. Reels/Shorts entry grace: the feed slide-in animation itself emits
        // TYPE_VIEW_SCROLLED events - opening the feed must never count as a swipe.
        if (now - targetModeEnterTime < TARGET_MODE_ENTRY_GRACE_MS) {
            return
        }

        // 3c. The fingerprint detector does the counting whenever it can read
        // this app's feed. Scroll gestures are only a fallback for layouts it
        // can't read (otherwise one swipe would be counted twice).
        if (ReelDetector.supports(packageName)) {
            if (!fingerprintActive(packageName) && canFingerprintNow(packageName)) {
                fingerprintPkgs.add(packageName)
            }
            if (fingerprintActive(packageName)) {
                requestScan(pkg = packageName)
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

            // NOTE: do NOT filter zero-delta (dx == 0 && dy == 0) events here!
            // Some feed pagers (e.g. YouTube Shorts' reel_player_page_view) emit
            // TYPE_VIEW_SCROLLED with scrollDeltaX/Y == 0 - filtering them stops
            // all counting on YouTube Shorts.

            // Horizontal swipe (switching tabs, audio carousels, chips) -> ignore!
            if (dx > 40 && dx > dy * 2) {
                return
            }
        }

        // 6. Gesture coalescing: one physical swipe is one continuous burst of scroll
        // events (drag frames, release, fling inertia, snap) all less than
        // GESTURE_GAP_MS apart. A quiet gap between events marks a NEW swipe, so
        // slow drags & settle animations are never counted twice.
        if (now - lastScrollEventTime > GESTURE_GAP_MS) {
            // Quiet gap detected -> a brand new physical swipe just started
            gestureCounted = false
        }
        lastScrollEventTime = now
        if (gestureCounted) {
            // Still the same swipe burst as the event we already counted -> skip
            return
        }
        gestureCounted = true
        countReel(packageName, now)
    }

    /** Records one video/swipe and shows the counter, check-in or block. */
    private fun countReel(packageName: String, now: Long) {
        // Hard-blocked for today: don't count, just put the block screen back.
        if (isBlockedToday()) {
            showBlock()
            return
        }

        // Genuine video swipe confirmed!
        if (sessionStartTime == 0L) sessionStartTime = now
        sessionScrollCount++

        // Persist natively (survives Flutter/MainActivity being dead).
        val today = TrackerPrefs.recordScroll(applicationContext, packageName)

        if (showFloatingCounter) {
            OverlayService.showCounter(this, "AntiDoom", today, currentLanguage)
        }
        handler.post { onScrollListener?.invoke(packageName, today) }

        if (TrackerPrefs.isSnoozedToday(applicationContext)) return
        val mode = when {
            forceBlockAt > 0 && today >= forceBlockAt -> OverlayService.Mode.BLOCK
            warnEvery > 0 && today % warnEvery == 0 -> OverlayService.Mode.CHECK_IN
            else -> return
        }
        if (OverlayService.showInterceptor(this, today, forceBlockAt, mode, currentLanguage)) {
            TrackerPrefs.recordIntervention(applicationContext)
            handler.post { onLimitReachedListener?.invoke(packageName, today) }
        }
    }

    private fun todayCount(): Int = TrackerPrefs.loadStats(applicationContext).scrolls

    private fun isBlockedToday(): Boolean =
        forceBlockAt > 0 && todayCount() >= forceBlockAt &&
            !TrackerPrefs.isSnoozedToday(applicationContext)

    private fun showBlock() {
        if (OverlayService.isInterceptorVisible()) return
        OverlayService.showInterceptor(
            this, todayCount(), forceBlockAt, OverlayService.Mode.BLOCK, currentLanguage
        )
    }

    private fun isTargetShortVideoMode(
        packageName: String,
        event: AccessibilityEvent?,
        root: AccessibilityNodeInfo? = null,
    ): Boolean {
        if (YouTubeApps.isYouTube(packageName)) return isYouTubeShorts(event, root, packageName)
        return when (packageName) {
            "com.instagram.android" -> isInstagramReels(event, root)
            "com.facebook.katana" -> isFacebookReels(event, root)
            "com.zhiliaoapp.musically", "com.ss.android.ugc.trill" -> isTikTokVideoFeed(event, root, packageName)
            "com.twitter.android" -> true // Twitter timeline
            else -> true
        }
    }

    private fun isConfirmedOutsideShortVideo(packageName: String): Boolean {
        val root = rootInActiveWindow ?: return false // If root is null during fling, do not assume left!

        if (YouTubeApps.isYouTube(packageName)) {
            // Check if Home or Subscriptions tab is selected
            val homeTabs = root.findAccessibilityNodeInfosByText("Home") +
                    root.findAccessibilityNodeInfosByText("Beranda")
            val isHomeTabSelected = homeTabs.any { it.isSelected || (it.parent?.isSelected == true) }

            val subsTabs = root.findAccessibilityNodeInfosByText("Subscriptions") +
                    root.findAccessibilityNodeInfosByText("Subscription") +
                    root.findAccessibilityNodeInfosByText("Koleksi")
            val isSubsTabSelected = subsTabs.any { it.isSelected || (it.parent?.isSelected == true) }

            val filterNodes = root.findAccessibilityNodeInfosByViewId(YouTubeApps.id(packageName, "feed_filter_bar"))
            val isFilterBarVisible = filterNodes.any { it.isVisibleToUser }

            return (isHomeTabSelected || isSubsTabSelected || isFilterBarVisible) &&
                !isYouTubeShorts(null, root, packageName)
        }

        return when (packageName) {
            "com.instagram.android" -> {
                val mainFeedNodes = root.findAccessibilityNodeInfosByViewId("com.instagram.android:id/main_feed") +
                        root.findAccessibilityNodeInfosByViewId("com.instagram.android:id/feed_recycler_view")
                val hasVisibleMainFeed = mainFeedNodes.any { it.isVisibleToUser }
                hasVisibleMainFeed && !isInstagramReels(null)
            }
            // The old reel_viewer / fb_shorts ids no longer exist, which made every
            // Facebook screen look "outside Reels". No instant exit here: the
            // debounced exit check (EXIT_CHECK_DELAY_MS) decides.
            "com.facebook.katana" -> false
            else -> false
        }
    }

    private fun isYouTubeShorts(
        event: AccessibilityEvent?,
        readRoot: AccessibilityNodeInfo? = null,
        ytPkg: String = YouTubeApps.OFFICIAL,
    ): Boolean {
        val root = readRoot ?: findRoot(ytPkg)
        if (root == null) {
            // Screen unreadable for a moment: fall back to hints from the event itself.
            val sourceRes = event?.source?.viewIdResourceName?.lowercase() ?: ""
            if ((sourceRes.contains("shorts") || sourceRes.contains("reel")) && !sourceRes.contains("shorts_shelf")) {
                return true
            }
            val className = event?.className?.toString()?.lowercase() ?: ""
            return className.contains("reel") || className.contains("shorts")
        }

        // Check if "Shorts" tab in bottom navigation is selected
        val shortsTabs = root.findAccessibilityNodeInfosByText("Shorts")
        if (shortsTabs.any { it.isSelected || (it.parent?.isSelected == true) }) {
            return true
        }

        val shortsViewIds = listOf(
            "reel_recycler",
            "reel_player_page_container",
            "shorts_container",
            "reel_player_page_view",
            "reel_player",
            "reel_view_holder",
            "shorts_video_player",
            "shorts_player",
            "reel_watch_fragment",
            "reel_swipe_indicator",
            "reel_feed_layout",
        ).map { YouTubeApps.id(ytPkg, it) }
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

    private fun isInstagramReels(event: AccessibilityEvent?, readRoot: AccessibilityNodeInfo? = null): Boolean {
        val root = readRoot ?: findRoot("com.instagram.android")
        if (root == null) {
            // Screen unreadable for a moment: fall back to hints from the event itself.
            // (Not used when the screen is readable: profile pages have "clips" ids too.)
            val sourceRes = event?.source?.viewIdResourceName?.lowercase() ?: ""
            if (sourceRes.contains("clips") || sourceRes.contains("reel_viewer")) return true
            val className = event?.className?.toString()?.lowercase() ?: ""
            return className.contains("clips") || className.contains("reel")
        }
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
                    if (isDebuggable) Log.v(TAG, "IG reels: visible $id")
                    return true
                }
            } catch (_: Exception) {}
        }

        return false
    }

    private fun isTikTokVideoFeed(
        event: AccessibilityEvent?,
        readRoot: AccessibilityNodeInfo? = null,
        tikTokPkg: String? = null,
    ): Boolean {
        val sourceRes = event?.source?.viewIdResourceName?.lowercase() ?: ""
        if (sourceRes.contains("comment") ||
            sourceRes.contains("profile") ||
            sourceRes.contains("search") ||
            sourceRes.contains("message") ||
            sourceRes.contains("chat")
        ) {
            return false
        }

        val pkg = tikTokPkg ?: event?.packageName?.toString() ?: return true
        val root = readRoot ?: findRoot(pkg) ?: return true
        // Only a video page counts as the feed; profile, inbox, search and shop
        // have no view_rootview (see ReelDetector.isTikTokFeed).
        val dm = resources.displayMetrics
        // The comments sheet sits on top of the feed: keep the counter (counting
        // pauses there anyway, see ReelDetector.isPaused).
        return ReelDetector.isTikTokFeed(root, pkg, dm.widthPixels, dm.heightPixels)
    }

    private fun isFacebookReels(event: AccessibilityEvent?, readRoot: AccessibilityNodeInfo? = null): Boolean {
        val root = readRoot ?: findRoot("com.facebook.katana")
        if (root == null) {
            // Screen unreadable for a moment: fall back to hints from the event itself.
            val sourceRes = event?.source?.viewIdResourceName?.lowercase() ?: ""
            return sourceRes.contains("fb_shorts") || sourceRes.contains("reel_viewer")
        }
        // Facebook strips view ids; ReelDetector finds the reel page by its text.
        val dm = resources.displayMetrics
        return ReelDetector.isFacebookFeed(root, dm.widthPixels, dm.heightPixels)
    }

    private fun isSystemOverlayPackage(pkg: String): Boolean {
        val lower = pkg.lowercase()
        return lower == "com.android.systemui" ||
                lower.contains("inputmethod") ||
                lower.contains("keyboard") ||
                lower.contains("ime")
    }

    private fun isPackageBlocklisted(pkg: String): Boolean {
        if (blocklist.contains(pkg)) return true
        // A modified YouTube (Morphe, ReVanced...) follows the YouTube rule.
        return YouTubeApps.isYouTube(pkg) && blocklist.contains(YouTubeApps.OFFICIAL)
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
        val until = System.currentTimeMillis() + (minutes * 60 * 1000)
        // Fresh window after the break: the unified counter restarts so the user
        // gets a full "stop at slide #N" window again after snoozing.
        resetSession()
        snoozeUntilTime = until
        OverlayService.dismissInterceptor(this)
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacksAndMessages(null)
        // Remove windows while `instance` is still set (OverlayService needs it)
        OverlayService.clearAll()
        instance = null
        if (isScreenReceiverRegistered) {
            try {
                unregisterReceiver(screenReceiver)
            } catch (_: Exception) {}
            isScreenReceiverRegistered = false
        }
    }
}
