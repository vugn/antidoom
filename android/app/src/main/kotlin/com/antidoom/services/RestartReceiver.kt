package com.antidoom.services

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.antidoom.utils.TrackerPrefs

/**
 * Brings the foreground service back after a reboot or an app update, if the
 * user had protection on. The accessibility service itself is rebound by the
 * system (on vendor ROMs only when auto-start is allowed); this makes sure the
 * persistent notification and its process priority come back with it.
 */
class RestartReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                if (!TrackerPrefs.loadConfig(context).trackingActive) return
                try {
                    AntiDoomForegroundService.startService(context)
                } catch (_: Exception) {
                    // Background start refused: the accessibility service retries on connect.
                }
            }
        }
    }
}
