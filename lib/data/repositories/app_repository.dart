import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../models/app_rule.dart';
import '../models/scroll_stat.dart';

class AppRepository {
  static const _keyRules = 'antidoom_app_rules';
  static const _keyOnboardingDone = 'antidoom_onboarding_done';
  static const _keyStatsToday = 'antidoom_stats_today';
  static const _keyLastDate = 'antidoom_last_date';
  static const _keyLanguage = 'antidoom_language_code';
  static const _keyScrollStopLimit = 'antidoom_scroll_stop_limit';
  static const _keyWarnEnabled = 'antidoom_warn_enabled';
  static const _keyForceBlockAt = 'antidoom_force_block_at';
  static const _keyWarnEvery = 'antidoom_warn_every';

  Future<int> getWarnEvery() async =>
      (await SharedPreferences.getInstance()).getInt(_keyWarnEvery) ?? 100;

  Future<void> setWarnEvery(int v) async =>
      (await SharedPreferences.getInstance()).setInt(_keyWarnEvery, v);

  Future<bool> getWarnEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_keyWarnEnabled) ?? true;

  Future<void> setWarnEnabled(bool v) async =>
      (await SharedPreferences.getInstance()).setBool(_keyWarnEnabled, v);

  Future<int> getForceBlockAt() async =>
      (await SharedPreferences.getInstance()).getInt(_keyForceBlockAt) ?? 0;

  Future<void> setForceBlockAt(int v) async =>
      (await SharedPreferences.getInstance()).setInt(_keyForceBlockAt, v);

  Future<int> getScrollStopLimit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyScrollStopLimit) ??
        AppConstants.defaultScrollStopLimit;
  }

  Future<void> setScrollStopLimit(int limit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyScrollStopLimit, limit);
  }

  Future<String> getLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage) ?? 'en'; // Default English dominant
  }

  Future<void> setLanguageCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, code);
  }

  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, completed);
  }

  Future<List<AppRule>> getRules() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyRules);

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List list = jsonDecode(jsonString) as List;
        return list
            .map((e) => AppRule.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    // Default rules
    final defaultRules = AppConstants.defaultTrackedApps.map((map) {
      return AppRule(
        id: map['package']!,
        appName: map['name']!,
        packageName: map['package']!,
        category: map['category']!,
        icon: map['icon']!,
        isEnabled: true,
        scrollLimit: AppConstants.defaultScrollThreshold,
        timeLimitMinutes: AppConstants.defaultTimeLimitMinutes,
      );
    }).toList();

    await saveRules(defaultRules);
    return defaultRules;
  }

  Future<void> saveRules(List<AppRule> rules) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(rules.map((r) => r.toJson()).toList());
    await prefs.setString(_keyRules, jsonString);
  }

  Future<ScrollStat> getTodayStats() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    final lastDate = prefs.getString(_keyLastDate);

    if (lastDate != todayStr) {
      // New day, reset daily metrics while keeping history
      await prefs.setString(_keyLastDate, todayStr);
      final initialStat = const ScrollStat(
        todayScrollCount: 0,
        todaySavedMinutes: 0,
        todayInterventions: 0,
        perAppScrolls: {},
        weeklyScrollHistory: [140, 110, 85, 95, 60, 45, 20],
      );
      await saveTodayStats(initialStat);
      return initialStat;
    }

    final savedJson = prefs.getString(_keyStatsToday);
    if (savedJson != null) {
      try {
        final Map<String, dynamic> data =
            jsonDecode(savedJson) as Map<String, dynamic>;
        final perApp =
            (data['perAppScrolls'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, v as int),
            ) ??
            {};
        return ScrollStat(
          todayScrollCount: data['todayScrollCount'] as int? ?? 0,
          todaySavedMinutes: data['todaySavedMinutes'] as int? ?? 0,
          todayInterventions: data['todayInterventions'] as int? ?? 0,
          perAppScrolls: perApp,
          weeklyScrollHistory:
              (data['weeklyScrollHistory'] as List?)
                  ?.map((e) => e as int)
                  .toList() ??
              const [140, 110, 85, 95, 60, 45, 20],
        );
      } catch (_) {}
    }

    return const ScrollStat();
  }

  Future<void> saveTodayStats(ScrollStat stats) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'todayScrollCount': stats.todayScrollCount,
      'todaySavedMinutes': stats.todaySavedMinutes,
      'todayInterventions': stats.todayInterventions,
      'perAppScrolls': stats.perAppScrolls,
      'weeklyScrollHistory': stats.weeklyScrollHistory,
    };
    await prefs.setString(_keyStatsToday, jsonEncode(data));
  }
}
