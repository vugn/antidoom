class ScrollStat {
  final int todayScrollCount;
  final int todaySavedMinutes;
  final int todayInterventions;
  final Map<String, int> perAppScrolls;
  final List<int> weeklyScrollHistory; // last 7 days

  const ScrollStat({
    this.todayScrollCount = 0,
    this.todaySavedMinutes = 0,
    this.todayInterventions = 0,
    this.perAppScrolls = const {},
    this.weeklyScrollHistory = const [120, 85, 94, 60, 42, 35, 18],
  });

  ScrollStat copyWith({
    int? todayScrollCount,
    int? todaySavedMinutes,
    int? todayInterventions,
    Map<String, int>? perAppScrolls,
    List<int>? weeklyScrollHistory,
  }) {
    return ScrollStat(
      todayScrollCount: todayScrollCount ?? this.todayScrollCount,
      todaySavedMinutes: todaySavedMinutes ?? this.todaySavedMinutes,
      todayInterventions: todayInterventions ?? this.todayInterventions,
      perAppScrolls: perAppScrolls ?? this.perAppScrolls,
      weeklyScrollHistory: weeklyScrollHistory ?? this.weeklyScrollHistory,
    );
  }
}
