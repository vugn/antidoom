package com.antidoom.services

import android.annotation.SuppressLint
import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.Looper
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import com.antidoom.MainActivity
import com.antidoom.utils.TrackerPrefs

/**
 * Draws the floating counter and the full-screen interceptor directly from the
 * AccessibilityService using TYPE_ACCESSIBILITY_OVERLAY.
 *
 * Why not a normal Service + TYPE_APPLICATION_OVERLAY (the old approach):
 *  - needs no SYSTEM_ALERT_WINDOW permission and is not blocked by OEM overlay
 *    toggles,
 *  - no startService() from background (crashes on Android 8+/12+),
 *  - the window lives exactly as long as the accessibility service.
 *
 * All methods are safe to call from any thread and are no-ops while the
 * accessibility service is not connected. The `context` parameters are kept for
 * source compatibility with existing callers.
 */
@Suppress("UNUSED_PARAMETER")
object OverlayService {

    private val mainHandler = Handler(Looper.getMainLooper())

    private var counterView: LinearLayout? = null
    private var counterText: TextView? = null
    private var interceptorView: View? = null

    private var currentScrollCount = 0
    private var currentLanguage = "en"

    private fun service(): AccessibilityService? = AntiDoomAccessibilityService.instance

    private fun windowManager(svc: AccessibilityService): WindowManager? =
        svc.getSystemService(Context.WINDOW_SERVICE) as? WindowManager

    private fun onMain(block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) block() else mainHandler.post(block)
    }

    // ---------------- Public API ----------------

    fun showCounter(context: Context, appName: String, scrollCount: Int, language: String = "en") {
        onMain {
            currentScrollCount = scrollCount
            currentLanguage = language
            createOrUpdateFloatingCounter()
        }
    }

    /** Updates the text only if the counter is currently visible (never resurrects a hidden one). */
    fun updateCounter(context: Context, scrollCount: Int, language: String = "en", appName: String? = null) {
        onMain {
            currentScrollCount = scrollCount
            currentLanguage = language
            updateCounterText()
        }
    }

    fun hideCounter(context: Context) {
        onMain { removeFloatingCounter() }
    }

    enum class Mode { CHECK_IN, BLOCK }

    /**
     * Shows the break screen. CHECK_IN offers "Keep going" / "Stop here";
     * BLOCK only offers "Close app". Returns true if it is (now) on screen.
     */
    fun showInterceptor(
        context: Context,
        count: Int,
        blockAt: Int,
        mode: Mode,
        language: String = "en"
    ): Boolean {
        if (Looper.myLooper() != Looper.getMainLooper()) {
            if (service() == null) return false
            mainHandler.post { showInterceptor(context, count, blockAt, mode, language) }
            return true
        }
        currentLanguage = language
        return showInterceptorOverlay(count, blockAt, mode, language)
    }

    fun dismissInterceptor(context: Context) {
        onMain { removeInterceptorOverlay() }
    }

    /** Called when the accessibility service goes away. */
    fun clearAll() {
        onMain {
            removeFloatingCounter()
            removeInterceptorOverlay()
        }
    }

    fun isInterceptorVisible(): Boolean = interceptorView != null

    // ---------------- Floating counter ----------------
    // A dark pill centered at the top of the screen: brain mascot + count.

    private var counterBrain: BrainView? = null

    /** How close today's count is to the next check-in / the hard block. */
    private fun moodFor(count: Int): BrainView.Mood {
        val blockAt = AntiDoomAccessibilityService.forceBlockAt
        val every = AntiDoomAccessibilityService.warnEvery
        val progress = when {
            blockAt > 0 -> count.toFloat() / blockAt
            every > 0 -> (count % every).toFloat() / every
            else -> 0f
        }
        return when {
            blockAt in 1..count -> BrainView.Mood.FRIED
            progress >= 0.9f -> BrainView.Mood.FRIED
            progress >= 0.7f -> BrainView.Mood.TIRED
            else -> BrainView.Mood.CALM
        }
    }

    private fun countColor(mood: BrainView.Mood): Int = Color.parseColor(
        when (mood) {
            BrainView.Mood.CALM -> "#F5F5F4"
            BrainView.Mood.TIRED -> "#FDB022"
            BrainView.Mood.FRIED -> "#F97066"
        }
    )

    @SuppressLint("ClickableViewAccessibility")
    private fun createOrUpdateFloatingCounter() {
        if (counterView != null) {
            updateCounterText()
            return
        }
        val svc = service() ?: return
        val wm = windowManager(svc) ?: return
        val density = svc.resources.displayMetrics.density
        fun dp(v: Int) = (v * density).toInt()

        val statusBar = svc.resources.getIdentifier("status_bar_height", "dimen", "android")
            .let { if (it > 0) svc.resources.getDimensionPixelSize(it) else dp(24) }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            x = 0
            y = statusBar + dp(6)
        }

        val mood = moodFor(currentScrollCount)

        val pill = LinearLayout(svc).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(6), dp(5), dp(16), dp(5))
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#EB141416"))
                cornerRadius = dp(24).toFloat()
                setStroke(dp(1), Color.parseColor("#33FFFFFF"))
            }
            elevation = dp(6).toFloat()
        }

        val brain = BrainView(svc).apply {
            this.mood = mood
            layoutParams = LinearLayout.LayoutParams(dp(32), dp(32)).apply {
                marginEnd = dp(8)
            }
        }

        val text = TextView(svc).apply {
            setTextColor(countColor(mood))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
            setTypeface(android.graphics.Typeface.create("sans-serif", android.graphics.Typeface.BOLD))
            fontFeatureSettings = "tnum"
            includeFontPadding = false
            this.text = "$currentScrollCount"
        }

        pill.addView(brain)
        pill.addView(text)

        // Draggable; a tap opens AntiDoom
        var initialX = 0
        var initialY = 0
        var touchX = 0f
        var touchY = 0f
        pill.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params.x
                    initialY = params.y
                    touchX = event.rawX
                    touchY = event.rawY
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    params.x = initialX + (event.rawX - touchX).toInt()
                    params.y = (initialY + (event.rawY - touchY).toInt()).coerceAtLeast(0)
                    try {
                        wm.updateViewLayout(pill, params)
                    } catch (_: Exception) {}
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (Math.abs(event.rawX - touchX) < 10 && Math.abs(event.rawY - touchY) < 10) {
                        openMainApp(svc)
                    }
                    true
                }
                else -> false
            }
        }

        try {
            wm.addView(pill, params)
            counterView = pill
            counterText = text
            counterBrain = brain
            // Drop-in entrance
            pill.alpha = 0f
            pill.translationY = -dp(16).toFloat()
            pill.animate().alpha(1f).translationY(0f).setDuration(220).start()
        } catch (e: Exception) {
            android.util.Log.e("AntiDoom", "addView(counter) failed", e)
        }
    }

    private fun updateCounterText() {
        val text = counterText ?: return
        val newText = "$currentScrollCount"
        if (text.text.toString() == newText) return
        val mood = moodFor(currentScrollCount)
        text.text = newText
        text.setTextColor(countColor(mood))
        counterBrain?.mood = mood
        // Small bump on every new swipe
        counterView?.let { v ->
            v.animate().cancel()
            v.scaleX = 1.12f
            v.scaleY = 1.12f
            v.animate().scaleX(1f).scaleY(1f).setDuration(180).start()
        }
    }

    private fun removeFloatingCounter() {
        val view = counterView ?: return
        try {
            service()?.let { windowManager(it)?.removeView(view) }
        } catch (_: Exception) {}
        counterView = null
        counterText = null
        counterBrain = null
    }

    // ---------------- Interceptor ----------------

    private fun showInterceptorOverlay(
        count: Int,
        blockAt: Int,
        mode: Mode,
        language: String
    ): Boolean {
        if (interceptorView != null) return true
        val svc = service() ?: return false
        val wm = windowManager(svc) ?: return false
        val density = svc.resources.displayMetrics.density
        fun dp(v: Int) = (v * density).toInt()
        val id = language == "id"
        val block = mode == Mode.BLOCK

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
            PixelFormat.TRANSLUCENT
        ).apply { gravity = Gravity.CENTER }

        val root = LinearLayout(svc).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#F20A0A0B"))
            setPadding(dp(28), dp(32), dp(28), dp(32))
            // Swallow touches so the feed underneath cannot be scrolled
            isClickable = true
        }

        val card = LinearLayout(svc).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(24), dp(32), dp(24), dp(24))
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#161618"))
                cornerRadius = dp(28).toFloat()
                setStroke(dp(1), Color.parseColor("#2A2A2E"))
            }
        }

        val big = TextView(svc).apply {
            text = "$count"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 64f)
            setTextColor(Color.parseColor(if (block) "#F97066" else "#F5F5F4"))
            gravity = Gravity.CENTER
            setTypeface(null, android.graphics.Typeface.BOLD)
            letterSpacing = -0.04f
        }

        val caption = TextView(svc).apply {
            text = if (id) "swipe hari ini" else "swipes today"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            setTextColor(Color.parseColor("#9A9A96"))
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, dp(20))
        }

        val title = TextView(svc).apply {
            text = when {
                block && id -> "Cukup untuk hari ini"
                block -> "Done for today"
                id -> "Masih mau lanjut?"
                else -> "Still worth it?"
            }
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 24f)
            setTextColor(Color.parseColor("#F5F5F4"))
            gravity = Gravity.CENTER
            setTypeface(null, android.graphics.Typeface.BOLD)
            setPadding(0, 0, 0, dp(8))
        }

        val body = TextView(svc).apply {
            text = when {
                block && id -> "Kamu sudah mencapai batas $blockAt swipe. Feed diblokir sampai besok."
                block -> "You hit your limit of $blockAt swipes. Feeds stay blocked until tomorrow."
                id -> "Kamu sudah swipe $count kali hari ini. Mau lanjut atau berhenti di sini?"
                else -> "You've swiped $count times today. Keep going, or stop here?"
            }
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            setTextColor(Color.parseColor("#9A9A96"))
            gravity = Gravity.CENTER
            setLineSpacing(0f, 1.35f)
            setPadding(0, 0, 0, dp(24))
        }

        fun button(label: String, bg: String, fg: String, onClick: () -> Unit) =
            Button(svc).apply {
                text = label
                isAllCaps = false
                setTextColor(Color.parseColor(fg))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
                stateListAnimator = null
                background = GradientDrawable().apply {
                    setColor(Color.parseColor(bg))
                    cornerRadius = dp(26).toFloat()
                }
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT, dp(52)
                ).apply { topMargin = dp(10) }
                setOnClickListener { onClick() }
            }

        val goHome = {
            removeInterceptorOverlay()
            svc.performGlobalAction(AccessibilityService.GLOBAL_ACTION_HOME)
            Unit
        }

        val snooze = {
            TrackerPrefs.snoozeToday(svc)
            removeInterceptorOverlay()
            Unit
        }
        val snoozeLabel = if (id) "Jeda sampai besok" else "Snooze for today"

        card.addView(big)
        card.addView(caption)
        card.addView(title)
        card.addView(body)
        if (block) {
            card.addView(button(if (id) "Tutup aplikasi" else "Close app", "#F5F5F4", "#0A0A0B", goHome))
            card.addView(button(snoozeLabel, "#222225", "#F5F5F4", snooze))
        } else {
            card.addView(button(if (id) "Berhenti di sini" else "Stop here", "#F5F5F4", "#0A0A0B", goHome))
            card.addView(button(if (id) "Lanjut" else "Keep going", "#222225", "#F5F5F4") {
                removeInterceptorOverlay()
            })
            card.addView(button(snoozeLabel, "#00000000", "#9A9A96", snooze))
        }
        val hint = TextView(svc).apply {
            text = if (id) "Jeda mematikan check-in dan blokir sampai besok."
            else "Snoozing turns off check-ins and blocks until tomorrow."
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            setTextColor(Color.parseColor("#5E5E5B"))
            gravity = Gravity.CENTER
            setPadding(0, dp(6), 0, 0)
        }
        card.addView(hint)
        root.addView(card)

        return try {
            wm.addView(root, params)
            interceptorView = root
            true
        } catch (e: Exception) {
            android.util.Log.e("AntiDoom", "addView(interceptor) failed", e)
            false
        }
    }

    private fun removeInterceptorOverlay() {
        val view = interceptorView ?: return
        try {
            service()?.let { windowManager(it)?.removeView(view) }
        } catch (_: Exception) {}
        interceptorView = null
    }

    private fun openMainApp(context: Context) {
        try {
            context.startActivity(Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            })
        } catch (e: Exception) {
            android.util.Log.e("AntiDoom", "openMainApp failed", e)
        }
    }
}
