package com.antidoom.services

/**
 * YouTube and its modified builds (Morphe, ReVanced, ReVanced Extended,
 * Vanced). They change the package name, and their view ids follow it
 * ("app.morphe.android.youtube:id/reel_recycler", checked on a device), so
 * every Shorts check builds ids from the package actually on screen.
 */
object YouTubeApps {
    const val OFFICIAL = "com.google.android.youtube"

    /** Shown as YouTube in the app and on the website copy. Keep in sync with social_apps.dart. */
    val KNOWN = setOf(
        OFFICIAL,
        "app.morphe.android.youtube",
        "app.revanced.android.youtube",
        "app.rvx.android.youtube",
        "com.vanced.android.youtube",
    )

    /** Known builds, plus any other "*.android.youtube" repackage. YouTube Music is not Shorts. */
    fun isYouTube(pkg: String): Boolean =
        pkg in KNOWN || (pkg.endsWith(".android.youtube") && !pkg.contains("music"))

    fun id(pkg: String, name: String) = "$pkg:id/$name"
}
