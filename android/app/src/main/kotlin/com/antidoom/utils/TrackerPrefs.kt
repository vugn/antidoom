package com.antidoom.utils

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONObject
import java.util.Calendar

/**
 * Native-owned persistent state. The accessibility service is the single source
 * of truth for tracking config and daily stats, so they survive process death,
 * reboot, and the Flutter activity being destroyed.
 */
object TrackerPrefs {
    private const val FILE = "antidoom_native"

    private const val K_ACTIVE = "tracking_active"
    private const val K_BLOCKLIST = "blocklist"
    private const val K_SCROLL_LIMIT = "scroll_limit"
    private const val K_TIME_LIMIT = "time_limit"
    private const val K_FLOATING = "show_floating"
    private const val K_LANGUAGE = "language"
    private const val K_WARN_EVERY = "warn_every"
    private const val K_FORCE_BLOCK_AT = "force_block_at"

    private const val K_STATS_DATE = "stats_date"
    private const val K_SNOOZE_DATE = "snooze_date"
    private const val K_STATS_SCROLLS = "stats_scrolls"
    private const val K_STATS_INTERVENTIONS = "stats_interventions"
    private const val K_STATS_PER_APP = "stats_per_app"
    private const val K_RECENT_REELS = "recent_reels"
    private const val K_RECENT_REELS_DATE = "recent_reels_date"

    class Config(
        val trackingActive: Boolean,
        val blocklist: Set<String>?,
        val scrollLimit: Int,
        val timeLimitSeconds: Int,
        val showFloating: Boolean,
        val language: String,
        val warnEvery: Int,
        val forceBlockAt: Int
    )

    private fun prefs(context: Context): SharedPreferences =
        context.applicationContext.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    // ---- Config ----

    fun loadConfig(context: Context): Config {
        val p = prefs(context)
        return Config(
            trackingActive = p.getBoolean(K_ACTIVE, false),
            // null = never configured -> caller keeps its built-in defaults
            blocklist = p.getStringSet(K_BLOCKLIST, null)?.toSet(),
            scrollLimit = p.getInt(K_SCROLL_LIMIT, 50),
            timeLimitSeconds = p.getInt(K_TIME_LIMIT, 900),
            showFloating = p.getBoolean(K_FLOATING, true),
            language = p.getString(K_LANGUAGE, "en") ?: "en",
            warnEvery = p.getInt(K_WARN_EVERY, 100),
            forceBlockAt = p.getInt(K_FORCE_BLOCK_AT, 0)
        )
    }

    fun saveConfig(
        context: Context,
        active: Boolean,
        blocklist: Set<String>,
        scrollLimit: Int,
        timeLimitSeconds: Int,
        showFloating: Boolean,
        language: String,
        warnEvery: Int,
        forceBlockAt: Int
    ) {
        prefs(context).edit()
            .putBoolean(K_ACTIVE, active)
            .putStringSet(K_BLOCKLIST, blocklist)
            .putInt(K_SCROLL_LIMIT, scrollLimit)
            .putInt(K_TIME_LIMIT, timeLimitSeconds)
            .putBoolean(K_FLOATING, showFloating)
            .putString(K_LANGUAGE, language)
            .putInt(K_WARN_EVERY, warnEvery)
            .putInt(K_FORCE_BLOCK_AT, forceBlockAt)
            .apply()
    }

    fun setActive(context: Context, active: Boolean) {
        prefs(context).edit().putBoolean(K_ACTIVE, active).apply()
    }

    fun setFloating(context: Context, show: Boolean) {
        prefs(context).edit().putBoolean(K_FLOATING, show).apply()
    }

    fun setLanguage(context: Context, language: String) {
        prefs(context).edit().putString(K_LANGUAGE, language).apply()
    }

    // ---- Snooze for today ----

    /** Turns off check-ins and the hard block until tomorrow. */
    fun snoozeToday(context: Context) {
        prefs(context).edit().putString(K_SNOOZE_DATE, today()).apply()
    }

    fun clearSnooze(context: Context) {
        prefs(context).edit().remove(K_SNOOZE_DATE).apply()
    }

    fun isSnoozedToday(context: Context): Boolean =
        prefs(context).getString(K_SNOOZE_DATE, null) == today()

    // ---- Recently counted videos (so a revisit isn't counted twice) ----

    fun loadRecentReels(context: Context): List<String> {
        val p = prefs(context)
        if (p.getString(K_RECENT_REELS_DATE, null) != today()) return emptyList()
        return p.getString(K_RECENT_REELS, null)?.split('\n')?.filter { it.isNotEmpty() } ?: emptyList()
    }

    fun saveRecentReels(context: Context, keys: Collection<String>) {
        prefs(context).edit()
            .putString(K_RECENT_REELS_DATE, today())
            .putString(K_RECENT_REELS, keys.joinToString("\n"))
            .apply()
    }

    // ---- Daily stats ----

    class Stats(
        val scrolls: Int,
        val interventions: Int,
        val perApp: Map<String, Int>
    )

    private fun today(): String {
        val c = Calendar.getInstance()
        return "${c.get(Calendar.YEAR)}-${c.get(Calendar.MONTH) + 1}-${c.get(Calendar.DAY_OF_MONTH)}"
    }

    /** Clears counters if the stored date is not today. */
    private fun rolloverIfNeeded(p: SharedPreferences) {
        val t = today()
        if (p.getString(K_STATS_DATE, null) != t) {
            p.edit()
                .putString(K_STATS_DATE, t)
                .putInt(K_STATS_SCROLLS, 0)
                .putInt(K_STATS_INTERVENTIONS, 0)
                .putString(K_STATS_PER_APP, "{}")
                .apply()
        }
    }

    @Synchronized
    /** Records one swipe and returns today's new total. */
    fun recordScroll(context: Context, packageName: String): Int {
        val p = prefs(context)
        rolloverIfNeeded(p)
        val perApp = try {
            JSONObject(p.getString(K_STATS_PER_APP, "{}") ?: "{}")
        } catch (_: Exception) {
            JSONObject()
        }
        perApp.put(packageName, perApp.optInt(packageName, 0) + 1)
        val total = p.getInt(K_STATS_SCROLLS, 0) + 1
        p.edit()
            .putInt(K_STATS_SCROLLS, total)
            .putString(K_STATS_PER_APP, perApp.toString())
            .apply()
        return total
    }

    @Synchronized
    fun recordIntervention(context: Context) {
        val p = prefs(context)
        rolloverIfNeeded(p)
        p.edit().putInt(K_STATS_INTERVENTIONS, p.getInt(K_STATS_INTERVENTIONS, 0) + 1).apply()
    }

    @Synchronized
    fun loadStats(context: Context): Stats {
        val p = prefs(context)
        rolloverIfNeeded(p)
        val perApp = HashMap<String, Int>()
        try {
            val obj = JSONObject(p.getString(K_STATS_PER_APP, "{}") ?: "{}")
            obj.keys().forEach { perApp[it] = obj.optInt(it, 0) }
        } catch (_: Exception) {}
        return Stats(
            scrolls = p.getInt(K_STATS_SCROLLS, 0),
            interventions = p.getInt(K_STATS_INTERVENTIONS, 0),
            perApp = perApp
        )
    }
}
