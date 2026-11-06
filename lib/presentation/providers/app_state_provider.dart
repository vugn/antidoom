import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/social_apps.dart';
import '../../data/models/app_rule.dart';
import '../../data/models/scroll_stat.dart';
import '../../data/repositories/app_repository.dart';
import '../../services/native_bridge.dart';

class AppState {
  final bool isTrackingActive;
  final bool isFloatingCounterEnabled;
  final Map<String, bool> permissions;
  final List<AppRule> rules;
  final ScrollStat stats;
  final String? currentActivePackage;
  final int currentSessionScrolls;
  final int scrollStopLimit;
  final bool isLoading;

  /// Check-in every 100 swipes today.
  final bool warnEnabled;

  /// Hard block once today's swipes reach this number (0 = off).
  final int forceBlockAt;

  /// Swipes between check-ins.
  final int warnEvery;

  /// User chose "Snooze for today" on a break screen.
  final bool snoozedToday;

  const AppState({
    this.isTrackingActive = false,
    this.isFloatingCounterEnabled = true,
    this.permissions = const {
      'accessibility': false,
      'batteryOptimization': false,
    },
    this.rules = const [],
    this.stats = const ScrollStat(),
    this.currentActivePackage,
    this.currentSessionScrolls = 0,
    this.scrollStopLimit = AppConstants.defaultScrollStopLimit,
    this.isLoading = true,
    this.warnEnabled = true,
    this.forceBlockAt = 0,
    this.warnEvery = 100,
    this.snoozedToday = false,
  });

  /// Overlays are drawn by the accessibility service, so the separate
  /// "display over other apps" permission is not required. Vendor steps
  /// (auto-start, MIUI background pop-ups) count only on phones that have them;
  /// native reports them as granted elsewhere.
  bool get areAllPermissionsGranted =>
      (permissions['accessibility'] ?? false) &&
      (permissions['batteryOptimization'] ?? false) &&
      (permissions['autostart'] ?? true) &&
      (permissions['popup'] ?? true);

  AppState copyWith({
    bool? isTrackingActive,
    bool? isFloatingCounterEnabled,
    Map<String, bool>? permissions,
    List<AppRule>? rules,
    ScrollStat? stats,
    String? currentActivePackage,
    int? currentSessionScrolls,
    int? scrollStopLimit,
    bool? isLoading,
    bool? warnEnabled,
    int? forceBlockAt,
    int? warnEvery,
    bool? snoozedToday,
  }) {
    return AppState(
      isTrackingActive: isTrackingActive ?? this.isTrackingActive,
      isFloatingCounterEnabled:
          isFloatingCounterEnabled ?? this.isFloatingCounterEnabled,
      permissions: permissions ?? this.permissions,
      rules: rules ?? this.rules,
      stats: stats ?? this.stats,
      currentActivePackage: currentActivePackage ?? this.currentActivePackage,
      currentSessionScrolls:
          currentSessionScrolls ?? this.currentSessionScrolls,
      scrollStopLimit: scrollStopLimit ?? this.scrollStopLimit,
      isLoading: isLoading ?? this.isLoading,
      warnEnabled: warnEnabled ?? this.warnEnabled,
      forceBlockAt: forceBlockAt ?? this.forceBlockAt,
      warnEvery: warnEvery ?? this.warnEvery,
      snoozedToday: snoozedToday ?? this.snoozedToday,
    );
  }
}

class AppStateNotifier extends Notifier<AppState> {
  late final AppRepository _repository;

  @override
  AppState build() {
    _repository = ref.watch(appRepositoryProvider);
    // Asynchronously load initial data
    Future.microtask(() => _init());
    return const AppState();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);

    NativeBridge.initializeListeners();
    NativeBridge.onScrollDetected = (packageName, scrollCount) {
      _handleNativeScroll(packageName, scrollCount);
    };

    NativeBridge.onLimitReached = (packageName, scrollCount) {
      _handleLimitReached(packageName, scrollCount);
    };

    final permissions = await NativeBridge.checkPermissions();
    final rules = await _repository.getRules();
    final stats = await _repository.getTodayStats();
    final scrollStopLimit = await _repository.getScrollStopLimit();
    final warnEnabled = await _repository.getWarnEnabled();
    final forceBlockAt = await _repository.getForceBlockAt();
    final warnEvery = await _repository.getWarnEvery();

    state = state.copyWith(
      permissions: permissions,
      rules: rules,
      stats: stats,
      scrollStopLimit: scrollStopLimit,
      warnEnabled: warnEnabled,
      forceBlockAt: forceBlockAt,
      warnEvery: warnEvery,
      isLoading: false,
    );

    await syncFromNative();
  }

  /// Native (accessibility service) is the source of truth for the tracking
  /// flag and today's counters. Call on startup and every time the app resumes.
  Future<void> syncFromNative() async {
    final permissions = await NativeBridge.checkPermissions();
    final native = await NativeBridge.getNativeStats();
    if (native.isEmpty) {
      state = state.copyWith(permissions: permissions);
      return;
    }

    final nativeTracking = native['isTracking'] as bool? ?? false;
    final perApp = <String, int>{};
    final rawPerApp = native['perAppScrolls'];
    if (rawPerApp is Map) {
      rawPerApp.forEach((k, v) => perApp[k.toString()] = (v as num).toInt());
    }
    final interventions = (native['todayInterventions'] as num?)?.toInt() ?? 0;

    final stats = state.stats.copyWith(
      todayScrollCount: (native['todayScrollCount'] as num?)?.toInt() ?? 0,
      todayInterventions: interventions,
      todaySavedMinutes: interventions * 15,
      perAppScrolls: perApp,
    );

    state = state.copyWith(
      permissions: permissions,
      // Tracking is only really on if the accessibility service is enabled
      isTrackingActive: nativeTracking && (permissions['accessibility'] ?? false),
      currentActivePackage: native['activePackage'] as String?,
      currentSessionScrolls: (native['sessionScrollCount'] as num?)?.toInt() ?? 0,
      snoozedToday: native['snoozedToday'] as bool? ?? false,
      // The switch lives natively. Without reading it back, the app started
      // with "on" every launch and the next config push (limit, rule,
      // language, protection) silently turned the counter back on.
      isFloatingCounterEnabled:
          native['showFloatingCounter'] as bool? ?? state.isFloatingCounterEnabled,
      stats: stats,
    );
    await _repository.saveTodayStats(stats);
  }

  Future<void> refreshPermissions() => syncFromNative();

  /// Pushes current rules/limit/language to native WITHOUT resetting the
  /// live session counter.
  /// Every package of every enabled app (e.g. both TikTok packages).
  static List<String> _blocklistFor(List<AppRule> rules) => [
        for (final r in rules.where((r) => r.isEnabled))
          ...(SocialApp.forPackage(r.packageName)?.packages ?? [r.packageName]),
      ];

  /// Pushes current config to native WITHOUT resetting the live counter.
  Future<void> _pushConfig() async {
    if (!state.isTrackingActive) return;
    final lang = await _repository.getLanguageCode();
    await NativeBridge.startTracking(
      blocklist: _blocklistFor(state.rules),
      scrollLimit: state.scrollStopLimit,
      showFloatingCounter: state.isFloatingCounterEnabled,
      language: lang,
      warnEvery: state.warnEnabled ? state.warnEvery : 0,
      forceBlockAt: state.forceBlockAt,
      resetSession: false,
    );
  }

  Future<void> setWarnEnabled(bool enabled) async {
    state = state.copyWith(warnEnabled: enabled);
    await _repository.setWarnEnabled(enabled);
    await _pushConfig();
  }

  Future<void> setWarnEvery(int value) async {
    state = state.copyWith(warnEvery: value, warnEnabled: true);
    await _repository.setWarnEvery(value);
    await _repository.setWarnEnabled(true);
    await _pushConfig();
  }

  /// Undo "Snooze for today": check-ins and the hard block apply again.
  Future<void> resumeToday() async {
    await NativeBridge.clearSnooze();
    await syncFromNative();
  }

  /// 0 turns the hard block off.
  Future<void> setForceBlockAt(int value) async {
    final v = value < 0 ? 0 : value;
    state = state.copyWith(forceBlockAt: v);
    await _repository.setForceBlockAt(v);
    await _pushConfig();
  }

  /// Explicitly enables/disables one app (used by onboarding).
  Future<void> setRuleEnabled(String ruleId, bool enabled) async {
    final updated = [
      for (final r in state.rules)
        r.id == ruleId ? r.copyWith(isEnabled: enabled) : r,
    ];
    state = state.copyWith(rules: updated);
    await _repository.saveRules(updated);
    await _pushConfig();
  }

  Future<void> toggleTracking(bool enable) async {
    if (enable) {
      final lang = await _repository.getLanguageCode();
      final success = await NativeBridge.startTracking(
        blocklist: _blocklistFor(state.rules),
        scrollLimit: state.scrollStopLimit,
        showFloatingCounter: state.isFloatingCounterEnabled,
        language: lang,
        warnEvery: state.warnEnabled ? state.warnEvery : 0,
        forceBlockAt: state.forceBlockAt,
      );
      state = state.copyWith(isTrackingActive: success);
    } else {
      await NativeBridge.stopTracking();
      state = state.copyWith(
        isTrackingActive: false,
        currentActivePackage: null,
        currentSessionScrolls: 0,
      );
    }
  }

  Future<void> toggleFloatingCounter(bool enable) async {
    await NativeBridge.toggleFloatingCounter(enable);
    state = state.copyWith(isFloatingCounterEnabled: enable);
  }

  Future<void> toggleRule(String ruleId) async {
    final updated = state.rules.map((rule) {
      if (rule.id == ruleId) {
        return rule.copyWith(isEnabled: !rule.isEnabled);
      }
      return rule;
    }).toList();

    state = state.copyWith(rules: updated);
    await _repository.saveRules(updated);

    await _pushConfig();
  }

  /// Sets the unified "stop at slide #N" limit for ALL monitored social media.
  /// If tracking is active, the native tracker is refreshed with the new limit.
  Future<void> setScrollStopLimit(int limit) async {
    final clamped = limit.clamp(
      AppConstants.minScrollStopLimit,
      AppConstants.maxScrollStopLimit,
    );
    state = state.copyWith(scrollStopLimit: clamped);
    await _repository.setScrollStopLimit(clamped);

    await _pushConfig();
  }

  /// Native already persisted the scroll; just refresh the UI from it.
  void _handleNativeScroll(String packageName, int scrollCount) {
    state = state.copyWith(
      currentActivePackage: packageName,
      currentSessionScrolls: scrollCount,
    );
    syncFromNative();
  }

  void _handleLimitReached(String packageName, int scrollCount) {
    syncFromNative();
  }

  Future<void> testTriggerOverlay({
    String appName = 'Instagram',
    int scrollCount = 50,
    String? message,
  }) async {
    final lang = await _repository.getLanguageCode();
    final defaultMessage = lang == 'id'
        ? 'Udah cukup ya, mata lu butuh istirahat. Tarik napas perlahan dan kembali ke dunia nyata.'
        : 'That\'s enough scrolling for now. Give your eyes a rest, take a deep breath, and return to reality.';

    await NativeBridge.triggerOverlay(
      appName: appName,
      message: message ?? defaultMessage,
      scrollCount: scrollCount,
    );
  }

  // Interactive sandbox simulation for testing scroll counter & overlay
  void simulateScroll(String packageName) {
    final count = state.currentSessionScrolls + 1;
    final perApp = Map<String, int>.from(state.stats.perAppScrolls);
    perApp[packageName] = (perApp[packageName] ?? 0) + 1;
    state = state.copyWith(
      currentActivePackage: packageName,
      currentSessionScrolls: count,
      stats: state.stats.copyWith(
        todayScrollCount: state.stats.todayScrollCount + 1,
        perAppScrolls: perApp,
      ),
    );
    if (state.currentSessionScrolls >= 15) {
      testTriggerOverlay(
        appName: packageName.contains('instagram')
            ? 'Instagram'
            : packageName.contains('music')
            ? 'TikTok'
            : 'YouTube Shorts',
        scrollCount: state.currentSessionScrolls,
      );
    }
  }
}

final appRepositoryProvider = Provider<AppRepository>((ref) {
  return AppRepository();
});

/// Real icons/labels of the tracked apps that are installed on this phone.
/// Every package variant of every supported app (e.g. TikTok is
/// com.zhiliaoapp.musically in some regions and com.ss.android.ugc.trill in
/// others), so "Not installed" only shows when no variant is on the phone.
final installedAppsProvider = FutureProvider<Map<String, InstalledApp>>((ref) {
  return NativeBridge.getAppInfo([
    for (final app in SocialApp.all) ...app.packages,
  ]);
});

final appStateProvider = NotifierProvider<AppStateNotifier, AppState>(() {
  return AppStateNotifier();
});
