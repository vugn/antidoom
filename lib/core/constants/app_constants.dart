class AppConstants {
  static const String appName = 'AntiDoom';
  static const String appTagline = 'Reclaim Your Time. Break the Loop.';
  static const String nativeChannel = 'com.antidoom/native';

  // Default Targets
  static const List<Map<String, String>> defaultTrackedApps = [
    {
      'name': 'Instagram',
      'package': 'com.instagram.android',
      'category': 'Reels & Feed',
      'icon': '📸',
    },
    {
      'name': 'TikTok',
      'package': 'com.zhiliaoapp.musically',
      'category': 'Short Videos',
      'icon': '🎵',
    },
    {
      'name': 'YouTube Shorts',
      'package': 'com.google.android.youtube',
      'category': 'Short Videos',
      'icon': '▶️',
    },
    {
      'name': 'X (Twitter)',
      'package': 'com.twitter.android',
      'category': 'Timeline',
      'icon': '🐦',
    },
    {
      'name': 'Facebook',
      'package': 'com.facebook.katana',
      'category': 'Reels & Feed',
      'icon': '👥',
    },
  ];

  static const int defaultScrollThreshold = 50;
  static const int defaultTimeLimitMinutes = 15;

  static const List<String> affirmationsEn = [
    'That\'s enough scrolling for now. Give your eyes a rest and take a deep breath.',
    'The real world holds infinitely more meaning than an endless algorithmic feed.',
    'Master your thumb; don\'t let algorithms dictate your focus and your day.',
    'One deep, conscious breath is worth more than a hundred short videos.',
    'The time you reclaim right now is fuel for your real-world dreams.',
    'You are in control. Put the phone down and reconnect with the present.',
  ];

  static const List<String> affirmationsId = [
    'Udah cukup ya, mata lu butuh istirahat. Tarik napas dulu.',
    'Dunia nyata jauh lebih berharga daripada endless scrolling.',
    'Kendalikan jempolmu, jangan biarkan algoritma mendikte harimu.',
    'Satu napas dalam bernilai lebih dari 100 video singkat.',
    'Waktu yang kamu hemat sekarang adalah energi untuk mimpimu.',
    'Kamu yang memegang kendali. Letakkan ponsel dan istirahatkan pikiranmu.',
  ];

  // Default is English (dominant)
  static const List<String> affirmations = affirmationsEn;

  static List<String> getAffirmations([String langCode = 'en']) {
    return langCode == 'id' ? affirmationsId : affirmationsEn;
  }
}
