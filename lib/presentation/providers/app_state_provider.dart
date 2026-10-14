import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final bool isLoading;

  const AppState({
    this.isTrackingActive = false,
    this.isFloatingCounterEnabled = true,
    this.permissions = const {
      'accessibility': false,
      'overlay': false,
      'batteryOptimization': false,
    },
    this.rules = const [],
    this.stats = const ScrollStat(),
    this.currentActivePackage,
    this.currentSessionScrolls = 0,
    this.isLoading = true,
  });

  bool get areAllPermissionsGranted =>
      (permissions['accessibility'] ?? false) &&
      (permissions['overlay'] ?? false) &&
      (permissions['batteryOptimization'] ?? false);

  AppState copyWith({
    bool? isTrackingActive,
    bool? isFloatingCounterEnabled,
    Map<String, bool>? permissions,
    List<AppRule>? rules,
    ScrollStat? stats,
    String? currentActivePackage,
    int? currentSessionScrolls,
    bool? isLoading,
  }) {
    return AppState(
      isTrackingActive: isTrackingActive ?? this.isTrackingActive,
      isFloatingCounterEnabled: isFloatingCounterEnabled ?? this.isFloatingCounterEnabled,
      permissions: permissions ?? this.permissions,
      rules: rules ?? this.rules,
      stats: stats ?? this.stats,
      currentActivePackage: currentActivePackage ?? this.currentActivePackage,
      currentSessionScrolls: currentSessionScrolls ?? this.currentSessionScrolls,
      isLoading: isLoading ?? this.isLoading,
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

    state = state.copyWith(
      permissions: permissions,
      rules: rules,
      stats: stats,
      isLoading: false,
    );
  }

  Future<void> refreshPermissions() async {
    final permissions = await NativeBridge.checkPermissions();
    state = state.copyWith(permissions: permissions);
  }

  Future<void> toggleTracking(bool enable) async {
    if (enable) {
      final activePackages = state.rules.where((r) => r.isEnabled).map((r) => r.packageName).toList();
      final lang = await _repository.getLanguageCode();
      final success = await NativeBridge.startTracking(
        blocklist: activePackages,
        scrollLimit: 50,
        showFloatingCounter: state.isFloatingCounterEnabled,
        language: lang,
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

    if (state.isTrackingActive) {
      final activePackages = updated.where((r) => r.isEnabled).map((r) => r.packageName).toList();
      final lang = await _repository.getLanguageCode();
      await NativeBridge.startTracking(
        blocklist: activePackages,
        showFloatingCounter: state.isFloatingCounterEnabled,
        language: lang,
      );
    }
  }

  Future<void> updateRuleLimit(String ruleId, int scrollLimit, int timeLimitMinutes) async {
    final updated = state.rules.map((rule) {
      if (rule.id == ruleId) {
        return rule.copyWith(scrollLimit: scrollLimit, timeLimitMinutes: timeLimitMinutes);
      }
      return rule;
    }).toList();

    state = state.copyWith(rules: updated);
    await _repository.saveRules(updated);
  }

  void _handleNativeScroll(String packageName, int scrollCount) {
    final updatedPerApp = Map<String, int>.from(state.stats.perAppScrolls);
    updatedPerApp[packageName] = (updatedPerApp[packageName] ?? 0) + 1;

    final updatedStats = state.stats.copyWith(
      todayScrollCount: state.stats.todayScrollCount + 1,
      todaySavedMinutes: (state.stats.todayScrollCount / 20).round(),
      perAppScrolls: updatedPerApp,
    );

    state = state.copyWith(
      currentActivePackage: packageName,
      currentSessionScrolls: scrollCount,
      stats: updatedStats,
    );
    _repository.saveTodayStats(updatedStats);
  }

  void _handleLimitReached(String packageName, int scrollCount) {
    final updatedStats = state.stats.copyWith(
      todayInterventions: state.stats.todayInterventions + 1,
      todaySavedMinutes: state.stats.todaySavedMinutes + 15,
    );
    state = state.copyWith(stats: updatedStats);
    _repository.saveTodayStats(updatedStats);
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
    final updatedStats = state.stats.copyWith(
      todayInterventions: state.stats.todayInterventions + 1,
      todaySavedMinutes: state.stats.todaySavedMinutes + 15,
    );
    state = state.copyWith(stats: updatedStats);
    await _repository.saveTodayStats(updatedStats);
  }

  // Interactive sandbox simulation for testing scroll counter & overlay
  void simulateScroll(String packageName) {
    _handleNativeScroll(packageName, state.currentSessionScrolls + 1);
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

final appStateProvider = NotifierProvider<AppStateNotifier, AppState>(() {
  return AppStateNotifier();
});
