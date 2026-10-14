class AppRule {
  final String id;
  final String appName;
  final String packageName;
  final String category;
  final String icon;
  final bool isEnabled;
  final int scrollLimit;
  final int timeLimitMinutes;

  const AppRule({
    required this.id,
    required this.appName,
    required this.packageName,
    required this.category,
    required this.icon,
    this.isEnabled = true,
    this.scrollLimit = 50,
    this.timeLimitMinutes = 15,
  });

  AppRule copyWith({
    String? id,
    String? appName,
    String? packageName,
    String? category,
    String? icon,
    bool? isEnabled,
    int? scrollLimit,
    int? timeLimitMinutes,
  }) {
    return AppRule(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      packageName: packageName ?? this.packageName,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      isEnabled: isEnabled ?? this.isEnabled,
      scrollLimit: scrollLimit ?? this.scrollLimit,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appName': appName,
      'packageName': packageName,
      'category': category,
      'icon': icon,
      'isEnabled': isEnabled,
      'scrollLimit': scrollLimit,
      'timeLimitMinutes': timeLimitMinutes,
    };
  }

  factory AppRule.fromJson(Map<String, dynamic> json) {
    return AppRule(
      id: json['id'] as String,
      appName: json['appName'] as String,
      packageName: json['packageName'] as String,
      category: json['category'] as String,
      icon: json['icon'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
      scrollLimit: json['scrollLimit'] as int? ?? 50,
      timeLimitMinutes: json['timeLimitMinutes'] as int? ?? 15,
    );
  }
}
