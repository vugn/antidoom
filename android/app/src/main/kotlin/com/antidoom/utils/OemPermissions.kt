package com.antidoom.utils

import android.app.AppOpsManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings

/**
 * Vendor settings that decide whether AntiDoom survives being swiped away or a
 * reboot. Stock Android has neither of these; Xiaomi, Oppo, Vivo, Huawei and
 * friends kill background apps unless the user allows them by hand.
 *
 *  - Auto-start: lets the system bring AntiDoom (and its accessibility service)
 *    back after the app is closed or the phone restarts.
 *  - Background pop-ups (MIUI only): lets the break screen open AntiDoom while
 *    another app is in front.
 *
 * Most vendors offer no API to read these switches, so a step is "done" when
 * we can read it (MIUI app-ops) or when the user has confirmed it.
 */
object OemPermissions {

    private const val PREFS = "antidoom_oem_permissions"
    private const val K_AUTOSTART = "autostart_confirmed"
    private const val K_POPUP = "popup_confirmed"

    // MIUI-only app-ops (not in the public SDK).
    private const val MIUI_OP_AUTO_START = 10008
    private const val MIUI_OP_BACKGROUND_START_ACTIVITY = 10021

    /** Known auto-start screens, most specific first. The first one that resolves wins. */
    private val AUTOSTART_SCREENS = listOf(
        // Xiaomi / Redmi / POCO (MIUI, HyperOS)
        ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity"),
        // Oppo / Realme / OnePlus (ColorOS)
        ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity"),
        ComponentName("com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity"),
        ComponentName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity"),
        // Vivo / iQOO (Funtouch, OriginOS)
        ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"),
        ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager"),
        ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity"),
        // Huawei / Honor (EMUI, MagicOS)
        ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"),
        ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.optimize.process.ProtectActivity"),
        ComponentName("com.hihonor.systemmanager", "com.hihonor.systemmanager.startupmgr.ui.StartupNormalAppListActivity"),
        // Asus (ZenUI) and Letv
        ComponentName("com.asus.mobilemanager", "com.asus.mobilemanager.autostart.AutoStartActivity"),
        ComponentName("com.letv.android.letvsafe", "com.letv.android.letvsafe.AutobootManageActivity"),
    )

    fun isMiui(): Boolean {
        if (Build.MANUFACTURER.equals("xiaomi", ignoreCase = true)) return true
        return !systemProperty("ro.miui.ui.version.name").isNullOrEmpty()
    }

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun resolves(context: Context, intent: Intent): Boolean =
        context.packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY) != null

    private fun autostartIntent(context: Context): Intent? =
        AUTOSTART_SCREENS
            .map { Intent().setComponent(it) }
            .firstOrNull { resolves(context, it) }

    private fun popupIntent(context: Context): Intent? {
        if (!isMiui()) return null
        val editor = Intent("miui.intent.action.APP_PERM_EDITOR").apply {
            setClassName("com.miui.securitycenter", "com.miui.permcenter.permissions.PermissionsEditorActivity")
            putExtra("extra_pkgname", context.packageName)
        }
        return if (resolves(context, editor)) editor else appDetails(context)
    }

    private fun appDetails(context: Context) =
        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${context.packageName}"))

    /** MIUI app-op state: true/false when readable, null when the ROM hides it. */
    private fun miuiOpAllowed(context: Context, op: Int): Boolean? {
        if (!isMiui()) return null
        return try {
            val ops = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val method = AppOpsManager::class.java.getMethod(
                "checkOpNoThrow", Int::class.javaPrimitiveType, Int::class.javaPrimitiveType, String::class.java
            )
            val mode = method.invoke(ops, op, Process.myUid(), context.packageName) as Int
            mode == AppOpsManager.MODE_ALLOWED
        } catch (_: Throwable) {
            null
        }
    }

    /** Status for the setup screen. Keys are read by NativeBridge.checkPermissions. */
    fun status(context: Context): Map<String, Boolean> {
        val p = prefs(context)
        val autostartNeeded = autostartIntent(context) != null
        val autostartRead = miuiOpAllowed(context, MIUI_OP_AUTO_START)
        val popupNeeded = popupIntent(context) != null
        val popupRead = miuiOpAllowed(context, MIUI_OP_BACKGROUND_START_ACTIVITY)
        return mapOf(
            "autostartNeeded" to autostartNeeded,
            "autostartCheckable" to (autostartRead != null),
            "autostart" to (!autostartNeeded || (autostartRead ?: p.getBoolean(K_AUTOSTART, false))),
            "popupNeeded" to popupNeeded,
            "popupCheckable" to (popupRead != null),
            "popup" to (!popupNeeded || (popupRead ?: p.getBoolean(K_POPUP, false))),
        )
    }

    /** Opens the vendor screen. Returns false if no screen could be opened. */
    fun open(context: Context, kind: String): Boolean {
        val target = when (kind) {
            "autostart" -> autostartIntent(context)
            "popup" -> popupIntent(context)
            else -> null
        } ?: return false
        return try {
            context.startActivity(target.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            true
        } catch (_: Exception) {
            // Some ROMs export the screen but refuse third-party callers.
            try {
                context.startActivity(appDetails(context).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    /** The user says they switched it on (or off) in a screen we cannot read. */
    fun confirm(context: Context, kind: String, granted: Boolean) {
        val key = when (kind) {
            "autostart" -> K_AUTOSTART
            "popup" -> K_POPUP
            else -> return
        }
        prefs(context).edit().putBoolean(key, granted).apply()
    }

    private fun systemProperty(name: String): String? = try {
        val cls = Class.forName("android.os.SystemProperties")
        cls.getMethod("get", String::class.java).invoke(null, name) as String?
    } catch (_: Throwable) {
        null
    }
}
