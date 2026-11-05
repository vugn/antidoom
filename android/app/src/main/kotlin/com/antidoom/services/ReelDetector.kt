package com.antidoom.services

import android.graphics.Rect
import android.view.accessibility.AccessibilityNodeInfo
import java.util.ArrayDeque
import java.util.Locale

/**
 * Identifies WHICH short video is on screen by building a fingerprint from its
 * visible text (creator handle, caption, title). Counting distinct fingerprints
 * is far more reliable than counting TYPE_VIEW_SCROLLED events: swipes that
 * bounce back, comment-sheet scrolls and fling/settle bursts don't change the
 * fingerprint, while auto-advanced videos (no scroll event at all) do.
 */
object ReelDetector {

    sealed class Result {
        /** Comments / share sheet is open: don't count, don't move the baseline. */
        object Paused : Result()
        /** In the feed but no usable text yet (loading, or app layout unknown). */
        object NoKey : Result()
        /**
         * [key] = one short hash per component ("creator|caption"), so the
         * stored history never contains what people watched. [label] is the
         * readable form, used only for debug logs.
         */
        data class Reel(val key: String, val label: String) : Result()
    }

    private const val YT = "com.google.android.youtube"
    private const val IG = "com.instagram.android"
    private const val FB = "com.facebook.katana"
    private val TIKTOK = setOf("com.zhiliaoapp.musically", "com.ss.android.ugc.trill")

    private const val MAX_NODES = 500
    private const val PART_LEN = 40
    /** Candidate texts collected before picking the caption. */
    private const val MAX_PARTS = 4

    /** Apps whose feed is one full-screen video at a time. */
    fun supports(pkg: String): Boolean = pkg == YT || pkg == IG || pkg == FB || pkg in TIKTOK

    private val PAUSE_IDS = mapOf(
        YT to listOf(
            "$YT:id/app_engagement_panel",
            "$YT:id/design_bottom_sheet",
        ),
        IG to listOf(
            "$IG:id/layout_comment_thread_edittext",
            "$IG:id/bottom_sheet_container",
        ),
    )

    private val TIKTOK_PAUSE_SUFFIXES = listOf(":id/comment_list", ":id/comment_container")

    /** Smallest node that holds the current video's page (falls back to root). */
    private val SCOPE_IDS = mapOf(
        YT to listOf(
            "$YT:id/reel_player_page_content",
            "$YT:id/reel_player_page_view",
        ),
        IG to listOf("$IG:id/clips_viewer_view_pager"),
    )

    /** "@creator", also inside "Go to channel @creator" / "Subscribe to @creator." */
    private val HANDLE = Regex("""(?<![\p{L}\p{N}_.])@[\p{L}\p{N}_.\-]{2,30}""")
    /** Instagram: "Reel by creator. Double tap to play or pause" (EN / ID). */
    private val REEL_BY = Regex("""(?i)\breel (?:by|oleh|dari) ([\p{L}\p{N}_.]{2,30}?)\.?(?:\s|$)""")
    /** Shorter texts are almost always buttons/labels, not captions. */
    private const val MIN_PART = 12
    private val NUMBER = Regex("""\d[\d.,:]*\s*[KkMmBb]?""")
    private val LETTER = Regex("""\p{L}""")

    /** Exact UI labels (EN + ID) that are never part of a video's identity. */
    private val LABELS = setOf(
        "home", "beranda", "shorts", "reels", "reel", "search", "cari", "telusuri", "create", "buat",
        "you", "anda", "kamu", "library", "koleksi", "subscriptions", "langganan", "inbox", "kotak masuk",
        "profile", "profil", "friends", "teman", "for you", "untuk anda", "untuk kamu", "following",
        "mengikuti", "explore", "jelajahi", "live", "camera", "kamera", "more", "lainnya", "more options",
        "opsi lainnya", "back", "kembali", "close", "tutup", "pause", "play", "jeda", "putar", "mute",
        "unmute", "video progress", "sponsored", "bersponsor", "ad", "iklan", "follow", "ikuti",
        "subscribe", "subscribed", "berlangganan", "like", "suka", "comment", "komentar", "share",
        "bagikan", "remix", "send", "kirim", "save", "simpan", "original audio", "audio asli", "trends",
        "notifications", "notifikasi", "messages", "pesan", "watch", "tonton", "menu",
        "view product", "lihat produk", "show more", "tampilkan lainnya", "selengkapnya", "please wait",
        "harap tunggu", "more actions", "tindakan lainnya", "skip video", "lewati video",
        "video unavailable", "video tidak tersedia", "see translation", "lihat terjemahan",
        "previous video", "next video", "video sebelumnya", "video berikutnya", "earns commission",
        "mendapatkan komisi", "products", "produk", "paid partnership", "kemitraan berbayar",
    )

    /** Action buttons whose description changes when tapped ("Like" -> "Unlike, 1.2K"). */
    private val ACTION_PREFIXES = listOf(
        "like", "unlike", "dislike", "suka", "batal suka", "tidak suka", "comment", "komentar",
        "view comment", "lihat komentar", "share", "bagikan", "remix", "subscribe", "berlangganan",
        "unsubscribe", "follow", "ikuti", "save", "simpan", "send", "kirim", "sound", "audio",
        "suara", "more actions", "tindakan lainnya", "go to channel", "buka channel", "add to",
        "tambahkan", "mute", "unmute", "bisukan", "view ", "lihat ", "see more", "lihat lainnya",
        "go to", "buka ", "open ", "visit", "kunjungi", "original sound", "suara asli", "audio asli", "original audio",
        "reel by", "reel oleh", "sponsored reel", "reposted", "diposting ulang", "liked by", "disukai oleh",
        "double tap", "ketuk dua kali", "suggested", "disarankan", "reshare", "jumlah dibagikan", "shared by", "dibagikan oleh",
        "turn sound", "matikan suara", "nyalakan suara", "profile picture", "foto profil",
    )

    private val CONTAINS_LABELS = listOf(
        "liked this", "menyukai ini", "menyukai reel", "profile picture", "foto profil",
        "sound off", "sound on", "suara mati", "suara nyala", "audio is muted", "double tap",
    )

    private val PROGRESS_MARKERS = listOf(
        " seconds of ", " second of ", " minutes of ", " minute of ", " detik dari ", " menit dari ",
    )

    fun detect(root: AccessibilityNodeInfo, pkg: String, screenW: Int, screenH: Int): Result {
        if (isPaused(root, pkg)) return Result.Paused
        val scope = SCOPE_IDS[pkg]?.firstNotNullOfOrNull { id ->
            safeFind(root, id).firstOrNull { it.isVisibleToUser }
        } ?: root

        val screen = Rect(0, 0, screenW, screenH)
        var handle: String? = null
        val parts = ArrayList<String>(MAX_PARTS)

        val queue = ArrayDeque<AccessibilityNodeInfo>()
        queue.add(scope)
        val bounds = Rect()
        var visited = 0
        while (queue.isNotEmpty() && visited < MAX_NODES) {
            val node = queue.poll() ?: break
            visited++
            if (!node.isVisibleToUser) continue
            node.getBoundsInScreen(bounds)
            // Only the page that's actually on screen (neighbour pages are off-screen).
            if (screenW > 0 && !screen.contains(bounds.centerX(), bounds.centerY())) continue

            for (raw in listOf(node.text, node.contentDescription)) {
                val text = raw?.toString()?.trim()?.replace('\n', ' ') ?: continue
                if (text.isEmpty()) continue
                if (handle == null) {
                    REEL_BY.find(text)?.let {
                        handle = "@" + it.groupValues[1].trimEnd('.').lowercase(Locale.ROOT)
                    } ?: HANDLE.find(text)?.let {
                        handle = it.value.trimEnd('.', '-').lowercase(Locale.ROOT)
                    }
                }
                if (parts.size < MAX_PARTS) clean(text)?.let { if (it !in parts) parts.add(it) }
            }
            if (handle != null && parts.size >= MAX_PARTS) break
            for (i in 0 until node.childCount) node.getChild(i)?.let(queue::add)
        }

        if (handle == null && parts.isEmpty()) return Result.NoKey
        // Creator + the caption (longest text: labels are short) is specific
        // enough; more text only adds things that can change while it plays.
        val caption = parts.maxByOrNull { it.length }
        val all = if (handle != null) listOfNotNull(handle, caption) else parts.sortedByDescending { it.length }.take(2)
        return Result.Reel(all.joinToString("|") { hash(it) }, all.joinToString("|"))
    }

    /** Normalises one candidate text, or null when it's UI chrome / a counter. */
    private fun clean(text: String): String? {
        val lower = text.lowercase(Locale.ROOT)
        if (PROGRESS_MARKERS.any { lower.contains(it) }) return null
        // Counters change while you watch (likes, views, timestamps): strip digits.
        val norm = NUMBER.replace(lower, "#").replace(Regex("""\s+"""), " ").trim()
        if (LETTER.findAll(norm).count() < 3) return null
        if (norm.length < MIN_PART || norm in LABELS) return null
        if (HANDLE.containsMatchIn(norm) && norm.length < 60) return null // "subscribe to @x"
        if (norm.length < 160 && ACTION_PREFIXES.any { norm.startsWith(it) }) return null
        if (CONTAINS_LABELS.any { norm.contains(it) }) return null
        // Prefix only: an expanded caption ("... more") stays the same key.
        // A trailing "…" marks long texts so they win when picking the caption.
        return norm.take(PART_LEN) + if (norm.length > PART_LEN) "…" else ""
    }

    /** Short, stable, non-reversible id for one fingerprint component. */
    private fun hash(text: String): String {
        val digest = java.security.MessageDigest.getInstance("SHA-256").digest(text.toByteArray())
        return digest.take(6).joinToString("") { "%02x".format(it) }
    }

    private fun isPaused(root: AccessibilityNodeInfo, pkg: String): Boolean {
        val ids = PAUSE_IDS[pkg] ?: if (pkg in TIKTOK) TIKTOK_PAUSE_SUFFIXES.map { pkg + it } else return false
        return ids.any { id -> safeFind(root, id).any { it.isVisibleToUser } }
    }

    private fun safeFind(root: AccessibilityNodeInfo, id: String): List<AccessibilityNodeInfo> =
        try {
            root.findAccessibilityNodeInfosByViewId(id) ?: emptyList()
        } catch (_: Exception) {
            emptyList()
        }

    /**
     * True when two fingerprints are the same video seen at different load
     * stages (e.g. "@user" first, "@user|caption" once the caption renders).
     */
    fun sameReel(a: String, b: String): Boolean {
        if (a == b) return true
        val pa = a.split('|').toSet()
        val pb = b.split('|').toSet()
        return pa.containsAll(pb) || pb.containsAll(pa)
    }
}
