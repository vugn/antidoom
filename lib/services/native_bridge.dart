import 'package:flutter/services.dart';
import '../core/constants/app_constants.dart';

typedef ScrollCallback = void Function(String packageName, int scrollCount);
typedef LimitReachedCallback = void Function(String packageName, int scrollCount);

class NativeBridge {
  static const MethodChannel _channel = MethodChannel(AppConstants.nativeChannel);

  static ScrollCallback? onScrollDetected;
  static LimitReachedCallback? onLimitReached;

  static void initializeListeners() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onScrollDetected':
          final args = call.arguments as Map?;
          final pkg = args?['package'] as String? ?? '';
          final count = args?['scrollCount'] as int? ?? 0;
          onScrollDetected?.call(pkg, count);
          break;

        case 'onLimitReached':
          final args = call.arguments as Map?;
          final pkg = args?['package'] as String? ?? '';
          final count = args?['scrollCount'] as int? ?? 0;
          onLimitReached?.call(pkg, count);
          break;
      }
    });
  }

  static Future<bool> startTracking({
    required List<String> blocklist,
    int scrollLimit = 50,
    int timeLimitSeconds = 900,
    bool showFloatingCounter = true,
    String language = 'en',
    bool resetSession = true,
    int warnEvery = 100,
    int forceBlockAt = 0,
  }) async {
    try {
      final res = await _channel.invokeMethod<bool>('startTracking', {
        'resetSession': resetSession,
        'warnEvery': warnEvery,
        'forceBlockAt': forceBlockAt,
        'blocklist': blocklist,
        'scrollLimit': scrollLimit,
        'timeLimit': timeLimitSeconds,
        'showFloatingCounter': showFloatingCounter,
        'language': language,
      });
      return res ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> setLanguage(String languageCode) async {
    try {
      final res = await _channel.invokeMethod<bool>('setLanguage', {
        'language': languageCode,
      });
      return res ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Debug: shows the floating counter for a few seconds.
  static Future<bool> previewCounter(int count) async {
    try {
      return await _channel.invokeMethod<bool>('previewCounter', {'count': count}) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Opens an https link in the browser (e.g. the GitHub repo).
  static Future<bool> openUrl(String url) async {
    try {
      return await _channel.invokeMethod<bool>('openUrl', {'url': url}) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> clearSnooze() async {
    try {
      await _channel.invokeMethod('clearSnooze');
    } on PlatformException {
      // ignore
    } on MissingPluginException {
      // ignore
    }
  }

  static Future<bool> stopTracking() async {
    try {
      final res = await _channel.invokeMethod<bool>('stopTracking');
      return res ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> triggerOverlay({
    required String appName,
    required String message,
    int scrollCount = 50,
  }) async {
    try {
      final res = await _channel.invokeMethod<bool>('triggerOverlay', {
        'appName': appName,
        'message': message,
        'scrollCount': scrollCount,
      });
      return res ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> dismissOverlay() async {
    try {
      final res = await _channel.invokeMethod<bool>('dismissOverlay');
      return res ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> toggleFloatingCounter(bool show) async {
    try {
      final res = await _channel.invokeMethod<bool>('toggleFloatingCounter', {
        'show': show,
      });
      return res ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<Map<String, bool>> checkPermissions() async {
    try {
      final res = await _channel.invokeMethod<Map>('checkPermissions');
      if (res != null) {
        // accessibility, batteryOptimization, plus the vendor steps from
        // OemPermissions.kt: autostart/popup with their *Needed/*Checkable flags.
        return {
          for (final e in res.entries)
            if (e.key is String && e.value is bool) e.key as String: e.value as bool,
        };
      }
    } on PlatformException {
      // Return false defaults on platforms/emulators without implementation
    }
    return {
      'accessibility': false,
      'batteryOptimization': false,
    };
  }

  static Future<void> requestAccessibilityPermission() async {
    try {
      await _channel.invokeMethod('requestAccessibilityPermission');
    } on PlatformException catch (_) {}
  }

  /// Opens a vendor screen: `autostart` or `popup` (MIUI). False if none opened.
  static Future<bool> openOemPermission(String kind) async {
    try {
      return await _channel.invokeMethod<bool>('openOemPermission', {'kind': kind}) ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Records the user's answer for a vendor switch we cannot read.
  static Future<void> confirmOemPermission(String kind, bool granted) async {
    try {
      await _channel.invokeMethod('confirmOemPermission', {'kind': kind, 'granted': granted});
    } on PlatformException catch (_) {}
  }

  static Future<void> requestBatteryOptimization() async {
    try {
      await _channel.invokeMethod('requestBatteryOptimization');
    } on PlatformException catch (_) {}
  }

  static Future<Map<String, dynamic>> getNativeStats() async {
    try {
      final res = await _channel.invokeMethod<Map>('getNativeStats');
      if (res != null) {
        return Map<String, dynamic>.from(res);
      }
    } on PlatformException catch (_) {}
    return {};
  }

  /// Real label + icon for each installed package (missing = not installed).
  static Future<Map<String, InstalledApp>> getAppInfo(List<String> packages) async {
    try {
      final res = await _channel.invokeMethod<Map>('getAppInfo', {'packages': packages});
      if (res == null) return {};
      return res.map((k, v) {
        final m = v as Map;
        return MapEntry(
          k as String,
          InstalledApp(label: m['label'] as String, icon: m['icon'] as Uint8List?),
        );
      });
    } on PlatformException {
      return {};
    } on MissingPluginException {
      return {};
    }
  }
}

class InstalledApp {
  final String label;
  final Uint8List? icon;
  const InstalledApp({required this.label, this.icon});
}
