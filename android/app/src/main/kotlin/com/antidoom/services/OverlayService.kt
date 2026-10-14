package com.antidoom.services

import android.annotation.SuppressLint
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.IBinder
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import com.antidoom.MainActivity

class OverlayService : Service() {

    private var windowManager: WindowManager? = null
    private var counterView: View? = null
    private var interceptorView: View? = null

    private var currentScrollCount = 0
    private var currentAppName = "Social Media"

    companion object {
        const val ACTION_SHOW_COUNTER = "com.antidoom.action.SHOW_COUNTER"
        const val ACTION_UPDATE_COUNTER = "com.antidoom.action.UPDATE_COUNTER"
        const val ACTION_HIDE_COUNTER = "com.antidoom.action.HIDE_COUNTER"
        const val ACTION_SHOW_INTERCEPTOR = "com.antidoom.action.SHOW_INTERCEPTOR"
        const val ACTION_DISMISS_INTERCEPTOR = "com.antidoom.action.DISMISS_INTERCEPTOR"

        const val EXTRA_SCROLL_COUNT = "extra_scroll_count"
        const val EXTRA_APP_NAME = "extra_app_name"
        const val EXTRA_MESSAGE = "extra_message"
        const val EXTRA_LANGUAGE = "extra_language"

        fun showCounter(context: Context, appName: String, scrollCount: Int, language: String = "en") {
            val intent = Intent(context, OverlayService::class.java).apply {
                action = ACTION_SHOW_COUNTER
                putExtra(EXTRA_APP_NAME, appName)
                putExtra(EXTRA_SCROLL_COUNT, scrollCount)
                putExtra(EXTRA_LANGUAGE, language)
            }
            context.startService(intent)
        }

        fun updateCounter(context: Context, scrollCount: Int, language: String = "en", appName: String? = null) {
            val intent = Intent(context, OverlayService::class.java).apply {
                action = ACTION_UPDATE_COUNTER
                putExtra(EXTRA_SCROLL_COUNT, scrollCount)
                putExtra(EXTRA_LANGUAGE, language)
                if (appName != null) {
                    putExtra(EXTRA_APP_NAME, appName)
                }
            }
            context.startService(intent)
        }

        fun hideCounter(context: Context) {
            val intent = Intent(context, OverlayService::class.java).apply {
                action = ACTION_HIDE_COUNTER
            }
            context.startService(intent)
        }

        fun showInterceptor(context: Context, appName: String, scrollCount: Int, message: String? = null, language: String = "en") {
            val intent = Intent(context, OverlayService::class.java).apply {
                action = ACTION_SHOW_INTERCEPTOR
                putExtra(EXTRA_APP_NAME, appName)
                putExtra(EXTRA_SCROLL_COUNT, scrollCount)
                putExtra(EXTRA_LANGUAGE, language)
                if (message != null) {
                    putExtra(EXTRA_MESSAGE, message)
                }
            }
            context.startService(intent)
        }

        fun dismissInterceptor(context: Context) {
            val intent = Intent(context, OverlayService::class.java).apply {
                action = ACTION_DISMISS_INTERCEPTOR
            }
            context.startService(intent)
        }
    }

    private var currentLanguage = "en"

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.getStringExtra(EXTRA_LANGUAGE)?.let {
            currentLanguage = it
        }

        when (intent?.action) {
            ACTION_SHOW_COUNTER -> {
                val app = intent.getStringExtra(EXTRA_APP_NAME) ?: "Feed"
                val count = intent.getIntExtra(EXTRA_SCROLL_COUNT, 0)
                currentAppName = app
                currentScrollCount = count
                createOrUpdateFloatingCounter()
            }
            ACTION_UPDATE_COUNTER -> {
                currentScrollCount = intent.getIntExtra(EXTRA_SCROLL_COUNT, currentScrollCount)
                intent.getStringExtra(EXTRA_APP_NAME)?.let {
                    currentAppName = it
                }
                updateFloatingCounterText()
            }
            ACTION_HIDE_COUNTER -> {
                removeFloatingCounter()
            }
            ACTION_SHOW_INTERCEPTOR -> {
                val app = intent.getStringExtra(EXTRA_APP_NAME) ?: currentAppName
                val count = intent.getIntExtra(EXTRA_SCROLL_COUNT, currentScrollCount)
                val defaultMsg = if (currentLanguage == "id") {
                    "Udah cukup ya, mata lu butuh istirahat. Tarik napas perlahan dan kembali ke dunia nyata."
                } else {
                    "You have scrolled enough for now. Give your eyes a rest, take a deep breath, and return to reality."
                }
                val msg = intent.getStringExtra(EXTRA_MESSAGE) ?: defaultMsg
                showInterceptorOverlay(app, count, msg, currentLanguage)
            }
            ACTION_DISMISS_INTERCEPTOR -> {
                removeInterceptorOverlay()
            }
        }
        return START_NOT_STICKY
    }

    // --- Floating Counter Overlay (Scrolling Counter di atas) ---
    @SuppressLint("ClickableViewAccessibility")
    private fun createOrUpdateFloatingCounter() {
        if (counterView != null) {
            updateFloatingCounterText()
            return
        }

        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.END
            x = dpToPx(16)
            y = dpToPx(48)
        }

        val pillLayout = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(dpToPx(12), dpToPx(8), dpToPx(12), dpToPx(8))
            gravity = Gravity.CENTER_VERTICAL

            // Calm dark Zen Green background pill
            val bg = GradientDrawable().apply {
                setColor(Color.parseColor("#CC121E19")) // Translucent dark green
                cornerRadius = dpToPx(20).toFloat()
                setStroke(dpToPx(1), Color.parseColor("#3327AE60"))
            }
            background = bg
        }

        val dotView = View(this).apply {
            val dotBg = GradientDrawable().apply {
                setColor(Color.parseColor("#27AE60"))
                shape = GradientDrawable.OVAL
            }
            background = dotBg
            val dotSize = dpToPx(8)
            layoutParams = LinearLayout.LayoutParams(dotSize, dotSize).apply {
                marginEnd = dpToPx(8)
            }
        }

        val textView = TextView(this).apply {
            id = View.generateViewId()
            setTextColor(Color.parseColor("#F5F6FA"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            val unit = if (currentLanguage == "id") "scroll" else "scrolls"
            text = "⚡ $currentScrollCount $unit • AntiDoom"
        }

        pillLayout.addView(dotView)
        pillLayout.addView(textView)

        // Make the floating bubble draggable
        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f

        pillLayout.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params.x
                    initialY = params.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    params.x = initialX - (event.rawX - initialTouchX).toInt()
                    params.y = initialY + (event.rawY - initialTouchY).toInt()
                    try {
                        windowManager?.updateViewLayout(pillLayout, params)
                    } catch (_: Exception) {}
                    true
                }
                MotionEvent.ACTION_UP -> {
                    // If short tap, open AntiDoom app
                    val diffX = Math.abs(event.rawX - initialTouchX)
                    val diffY = Math.abs(event.rawY - initialTouchY)
                    if (diffX < 10 && diffY < 10) {
                        openMainApp()
                    }
                    true
                }
                else -> false
            }
        }

        try {
            windowManager?.addView(pillLayout, params)
            counterView = pillLayout
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun updateFloatingCounterText() {
        if (counterView == null) {
            createOrUpdateFloatingCounter()
            return
        }
        counterView?.let { view ->
            if (view is LinearLayout && view.childCount >= 2) {
                val tv = view.getChildAt(1) as? TextView
                val unit = if (currentLanguage == "id") "scroll" else "scrolls"
                tv?.text = "⚡ $currentScrollCount $unit • AntiDoom"
            }
        }
    }

    private fun removeFloatingCounter() {
        counterView?.let {
            try {
                windowManager?.removeView(it)
            } catch (_: Exception) {}
            counterView = null
        }
    }

    // --- The Interceptor (Full-screen Zen Blocking Screen) ---
    private fun showInterceptorOverlay(appName: String, scrollCount: Int, message: String, language: String = "en") {
        if (interceptorView != null) return

        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.CENTER
        }

        val rootLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#F50C1014")) // Calming deep AMOLED overlay
            setPadding(dpToPx(28), dpToPx(32), dpToPx(28), dpToPx(32))
        }

        // Card Container
        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dpToPx(24), dpToPx(28), dpToPx(24), dpToPx(28))

            val cardBg = GradientDrawable().apply {
                setColor(Color.parseColor("#1A232D"))
                cornerRadius = dpToPx(24).toFloat()
                setStroke(dpToPx(1), Color.parseColor("#27AE60"))
            }
            background = cardBg
        }

        // Zen Shield/Pause Icon Badge
        val iconBadge = TextView(this).apply {
            text = "🛡️"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 48f)
            gravity = Gravity.CENTER
        }

        // Headline
        val title = TextView(this).apply {
            text = if (language == "id") "Kendalikan Waktumu" else "Reclaim Your Time"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
            setTextColor(Color.parseColor("#F5F6FA"))
            gravity = Gravity.CENTER
            setTypeface(null, android.graphics.Typeface.BOLD)
            setPadding(0, dpToPx(16), 0, dpToPx(8))
        }

        // Affirmation Message
        val body = TextView(this).apply {
            text = message
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            setTextColor(Color.parseColor("#BDC3C7"))
            gravity = Gravity.CENTER
            setLineSpacing(0f, 1.4f)
        }

        // Scroll Stats Pill
        val statsPill = TextView(this).apply {
            text = if (language == "id") "Sudah $scrollCount scroll di $appName" else "$scrollCount scrolls on $appName"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            setTextColor(Color.parseColor("#27AE60"))
            gravity = Gravity.CENTER
            val pillBg = GradientDrawable().apply {
                setColor(Color.parseColor("#122A1E"))
                cornerRadius = dpToPx(12).toFloat()
            }
            background = pillBg
            setPadding(dpToPx(14), dpToPx(8), dpToPx(14), dpToPx(8))
            val lp = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(0, dpToPx(20), 0, dpToPx(24))
            }
            layoutParams = lp
        }

        // Action Button: Close App (Go to home screen)
        val btnClose = Button(this).apply {
            text = if (language == "id") "Tutup Aplikasi (Istirahat Dulu)" else "Close App (Take a Break)"
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            val btnBg = GradientDrawable().apply {
                setColor(Color.parseColor("#27AE60"))
                cornerRadius = dpToPx(14).toFloat()
            }
            background = btnBg
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(50)
            ).apply {
                bottomMargin = dpToPx(12)
            }
            setOnClickListener {
                goToHomeScreen()
                removeInterceptorOverlay()
            }
        }

        // Action Button: Snooze / Jeda 5 Menit
        val btnPause = Button(this).apply {
            text = if (language == "id") "Jeda 5 Menit" else "Snooze 5 Minutes"
            setTextColor(Color.parseColor("#BDC3C7"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            val btnBg = GradientDrawable().apply {
                setColor(Color.parseColor("#252E38"))
                cornerRadius = dpToPx(14).toFloat()
            }
            background = btnBg
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(44)
            )
            setOnClickListener {
                removeInterceptorOverlay()
            }
        }

        card.addView(iconBadge)
        card.addView(title)
        card.addView(body)
        card.addView(statsPill)
        card.addView(btnClose)
        card.addView(btnPause)

        rootLayout.addView(card)

        try {
            windowManager?.addView(rootLayout, params)
            interceptorView = rootLayout
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun removeInterceptorOverlay() {
        interceptorView?.let {
            try {
                windowManager?.removeView(it)
            } catch (_: Exception) {}
            interceptorView = null
        }
    }

    private fun goToHomeScreen() {
        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(homeIntent)
    }

    private fun openMainApp() {
        val appIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        startActivity(appIntent)
    }

    private fun dpToPx(dp: Int): Int {
        return (dp * resources.displayMetrics.density).toInt()
    }

    override fun onDestroy() {
        super.onDestroy()
        removeFloatingCounter()
        removeInterceptorOverlay()
    }
}
