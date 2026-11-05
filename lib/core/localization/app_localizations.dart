import 'dart:math';
import 'package:flutter/widgets.dart';

/// AntiDoom Localization Base
abstract class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizationsEn();
  }

  // General & Meta
  String get appName;
  String get appTagline;
  String get active;
  String get inactive;
  String get enabled;
  String get disabled;
  String get today;
  String get language;
  String get english;
  String get indonesian;
  String get selectLanguage;
  String get currentLanguageCode;

  // Header
  String get headerTagline;
  String get headlineActive;
  String get headlinePaused;
  String get dailyScrollLog;
  String get todaySummary;
  String get tabMore;

  // Master switch
  String get masterActiveTitle;
  String get masterPausedTitle;
  String get masterActiveDesc;
  String get masterPausedDesc;

  // Permissions Banner
  String get missingPermissionsBanner;

  // Hero Stats Card
  String get heroTodayAchievement;
  String heroScrollsMonitored(int count);
  String get heroTimeSavedLabel;
  String heroTimeSavedValue(int minutes);
  String get heroInterventionsLabel;
  String heroInterventionsValue(int count);

  // Live Scroll Monitor Card
  String get floatingCounterTitle;
  String get floatingCounterDesc;
  String get readyToDetectFeed;
  String get simulateScrollBtn;
  String get testInterceptorBtn;
  String scrollsProgress(int current, int max);

  // Daily Breakdown Card
  String get todayActivityTitle;
  String appsMonitoredCount(int count);
  String scrollsCounted(int count);

  // Quick Action Buttons
  String get targetAppsBtn;
  String get permissionStatusBtn;

  // Blocklist Screen
  String get blocklistScreenTitle;
  String get blocklistHeading;
  String get blocklistSubtitle;
  String get stopAtSlideTitle;
  String get stopAtSlideSubtitle;
  String stopAtSlideValue(int count);
  String get decreaseLimit;
  String get increaseLimit;
  String get privacyFirstTitle;
  String get privacyFirstDesc;

  // Onboarding Screen
  String get onboardingPermissionsBadge;
  String get onboardingHeroTitle;
  String get onboardingHeroSubtitle;
  String get permAccessibilityTitle;
  String get permAccessibilityDesc;
  String get permOverlayTitle;
  String get permOverlayDesc;
  String get permBatteryTitle;
  String get permBatteryDesc;
  String get grantPermissionBtn;
  String get permissionGrantedBadge;
  String get startProtectingBtn;
  String get continueToDashboardBtn;

  // Zen Overlay Interceptor / Preview Dialog
  String get overlayTitle;
  String get overlayDefaultAffirmation;
  String overlayStatsCount(int count, String appName);
  String get overlayCloseAppBtn;
  String get overlaySnoozeBtn;
  String get overlaySuccessSnackbar;

  // Affirmations
  List<String> get affirmations;
  String getRandomAffirmation() {
    final list = affirmations;
    return list[Random().nextInt(list.length)];
  }
}

/// English Implementation (Dominant & Default)
class AppLocalizationsEn extends AppLocalizations {
  @override
  String get currentLanguageCode => 'en';

  @override
  String get appName => 'AntiDoom';

  @override
  String get appTagline => 'Break the Loop • Reclaim Time';

  @override
  String get active => 'ACTIVE';

  @override
  String get inactive => 'INACTIVE';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get today => 'Today';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get indonesian => 'Bahasa Indonesia';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get headerTagline => 'Break the Loop • Reclaim Time';

@override
String get headlineActive => 'Stay present.\nYou\'re protected.';

@override
String get headlinePaused => 'Ready to take\nyour time back?';

@override
String get dailyScrollLog => 'Daily scroll log';

@override
String get todaySummary => 'Today\'s summary';

@override
String get tabMore => 'More';

  @override
  String get masterActiveTitle => 'AntiDoom Protection Active 🛡️';

  @override
  String get masterPausedTitle => 'AntiDoom Protection Paused';

  @override
  String get masterActiveDesc => 'Monitoring feeds & curbing doomscrolling';

  @override
  String get masterPausedDesc => 'Tap switch to activate tracker';

  @override
  String get missingPermissionsBanner =>
      'Some system permissions are missing. Tap here to complete setup.';

  @override
  String get heroTodayAchievement => "Today's Achievements";

  @override
  String heroScrollsMonitored(int count) => 'scrolls monitored';

  @override
  String get heroTimeSavedLabel => 'Time Saved';

  @override
  String heroTimeSavedValue(int minutes) => '$minutes min';

  @override
  String get heroInterventionsLabel => 'Mindful Pauses';

  @override
  String heroInterventionsValue(int count) => '$count times';

  @override
  String get floatingCounterTitle => 'Floating Scroll Counter';

  @override
  String get floatingCounterDesc => 'Live counter bubble on top of apps';

  @override
  String get readyToDetectFeed => 'Ready to detect feed';

  @override
  String get simulateScrollBtn => 'Simulate Scroll (+1)';

  @override
  String get testInterceptorBtn => 'Test Interceptor';

  @override
  String scrollsProgress(int current, int max) => '$current / $max swipes';

  @override
  String get todayActivityTitle => "Today's App Activity";

  @override
  String appsMonitoredCount(int count) => '$count monitored';

  @override
  String scrollsCounted(int count) => '$count scrolls';

  @override
  String get targetAppsBtn => 'Target Apps';

  @override
  String get permissionStatusBtn => 'Permissions';

  @override
  String get blocklistScreenTitle => 'Target Apps & Limits';

  @override
  String get blocklistHeading => 'Configure Apps & Scroll Limits';

  @override
  String get blocklistSubtitle =>
      'Choose which feed apps to track. One unified overlay protects all of them at once - the stop limit applies across every social media app.';

  @override
  String get stopAtSlideTitle => 'Stop Doom Scroll At';

  @override
  String get stopAtSlideSubtitle =>
      'One limit for all social media. The overlay appears once you reach this slide number, wherever you scroll.';

  @override
  String stopAtSlideValue(int count) => 'Slide #$count';

  @override
  String get decreaseLimit => 'Decrease limit';

  @override
  String get increaseLimit => 'Increase limit';

  @override
  String get privacyFirstTitle => '100% Privacy-First & Offline';

  @override
  String get privacyFirstDesc =>
      'AntiDoom never reads your feeds, personal messages, or watched videos. AntiDoom only monitors scroll gestures and app package identifiers locally on your device.';

  @override
  String get onboardingPermissionsBadge => 'Android System Permissions';

  @override
  String get onboardingHeroTitle =>
      'Reclaim Your Time.\nBreak the Scroll Loop.';

  @override
  String get onboardingHeroSubtitle =>
      'AntiDoom is 100% open-source & processes all telemetry strictly on your device without remote servers. To monitor feeds and present mindful overlays, please enable the 3 permissions below:';

  @override
  String get permAccessibilityTitle => '1. Accessibility Service';

  @override
  String get permAccessibilityDesc =>
      'Detects when you open Reels/TikTok/Shorts and measures real-time scroll counts.';

  @override
  String get permOverlayTitle => '2. Display Over Other Apps (Overlay)';

  @override
  String get permOverlayDesc =>
      'Displays the floating scroll counter bubble and the full-screen mindful break interceptor.';

  @override
  String get permBatteryTitle => '3. Disable Battery Optimization';

  @override
  String get permBatteryDesc =>
      'Ensures the background monitoring service stays alive without unexpected termination by the OS.';

  @override
  String get grantPermissionBtn => 'Enable Permission';

  @override
  String get permissionGrantedBadge => 'Granted';

  @override
  String get startProtectingBtn => 'Start Protecting My Focus 🌱';

  @override
  String get continueToDashboardBtn => 'Continue to Dashboard';

  @override
  String get overlayTitle => 'Reclaim Your Time';

  @override
  String get overlayDefaultAffirmation =>
      'You have scrolled enough for now. Give your eyes a rest, take a deep breath, and return to reality.';

  @override
  String overlayStatsCount(int count, String appName) =>
      '$count scrolls on $appName';

  @override
  String get overlayCloseAppBtn => 'Close App (Take a Break)';

  @override
  String get overlaySnoozeBtn => 'Snooze 5 Minutes';

  @override
  String get overlaySuccessSnackbar =>
      'Intervention successful: Time saved! 🌱';

  @override
  List<String> get affirmations => const [
    'That\'s enough scrolling for now. Give your eyes a rest and take a deep breath.',
    'The real world holds infinitely more meaning than an endless algorithmic feed.',
    'Master your thumb; don\'t let algorithms dictate your focus and your day.',
    'One deep, conscious breath is worth more than a hundred short videos.',
    'The time you reclaim right now is fuel for your real-world dreams.',
    'You are in control. Put the phone down and reconnect with the present.',
  ];
}

/// Indonesian Implementation
class AppLocalizationsId extends AppLocalizations {
  @override
  String get currentLanguageCode => 'id';

  @override
  String get appName => 'AntiDoom';

  @override
  String get appTagline => 'Putuskan Lingkaran • Kendalikan Waktu';

  @override
  String get active => 'AKTIF';

  @override
  String get inactive => 'NONAKTIF';

  @override
  String get enabled => 'Aktif';

  @override
  String get disabled => 'Nonaktif';

  @override
  String get today => 'Hari Ini';

  @override
  String get language => 'Bahasa';

  @override
  String get english => 'English';

  @override
  String get indonesian => 'Bahasa Indonesia';

  @override
  String get selectLanguage => 'Pilih Bahasa';

  @override
  String get headerTagline => 'Break the Loop • Reclaim Time';

@override
String get headlineActive => 'Tetap hadir.\nKamu terlindungi.';

@override
String get headlinePaused => 'Siap ambil lagi\nwaktumu?';

@override
String get dailyScrollLog => 'Log scroll harian';

@override
String get todaySummary => 'Ringkasan hari ini';

@override
String get tabMore => 'Lainnya';

  @override
  String get masterActiveTitle => 'Proteksi AntiDoom Aktif 🛡️';

  @override
  String get masterPausedTitle => 'Proteksi AntiDoom Jeda';

  @override
  String get masterActiveDesc => 'Memantau aktivitas & membatasi doomscroll';

  @override
  String get masterPausedDesc => 'Ketuk switch untuk mengaktifkan pemantau';

  @override
  String get missingPermissionsBanner =>
      'Beberapa izin sistem belum aktif. Ketuk di sini untuk menyelesaikan konfigurasi.';

  @override
  String get heroTodayAchievement => 'Pencapaian Hari Ini';

  @override
  String heroScrollsMonitored(int count) => 'scrolls terpantau';

  @override
  String get heroTimeSavedLabel => 'Waktu Dihemat';

  @override
  String heroTimeSavedValue(int minutes) => '$minutes mnt';

  @override
  String get heroInterventionsLabel => 'Intervensi Jeda';

  @override
  String heroInterventionsValue(int count) => '$count kali';

  @override
  String get floatingCounterTitle => 'Floating Scroll Counter';

  @override
  String get floatingCounterDesc => 'Overlay gelembung di atas aplikasi';

  @override
  String get readyToDetectFeed => 'Siap mendeteksi feed';

  @override
  String get simulateScrollBtn => 'Simulasi Scroll (+1)';

  @override
  String get testInterceptorBtn => 'Tes Interceptor';

  @override
  String scrollsProgress(int current, int max) => '$current / $max swipes';

  @override
  String get todayActivityTitle => 'Aktivitas Aplikasi Hari Ini';

  @override
  String appsMonitoredCount(int count) => '$count dipantau';

  @override
  String scrollsCounted(int count) => '$count scroll';

  @override
  String get targetAppsBtn => 'Atur Target App';

  @override
  String get permissionStatusBtn => 'Status Izin';

  @override
  String get blocklistScreenTitle => 'Target Aplikasi & Batas';

  @override
  String get blocklistHeading => 'Atur Aplikasi & Batas Scroll';

  @override
  String get blocklistSubtitle =>
      'Pilih aplikasi feed yang ingin dipantau. Satu overlay menyatukan semuanya - batasnya berlaku di semua sosmed.';

  @override
  String get stopAtSlideTitle => 'Stop Doom Scroll Di';

  @override
  String get stopAtSlideSubtitle =>
      'Satu batasan untuk semua sosmed. Overlay muncul saat kamu mencapai slide ke angka ini, di aplikasi apa pun.';

  @override
  String stopAtSlideValue(int count) => 'Slide ke-$count';

  @override
  String get decreaseLimit => 'Kurangi batas';

  @override
  String get increaseLimit => 'Tambah batas';

  @override
  String get privacyFirstTitle => '100% Privacy-First & Offline';

  @override
  String get privacyFirstDesc =>
      'AntiDoom tidak pernah membaca isi postingan, chat, atau video Anda. AntiDoom hanya menghitung event scroll dan nama package secara lokal di HP.';

  @override
  String get onboardingPermissionsBadge => 'Izin Akses Sistem Android';

  @override
  String get onboardingHeroTitle =>
      'Kendalikan Waktumu.\nPutuskan Lingkaran Scroll.';

  @override
  String get onboardingHeroSubtitle =>
      'AntiDoom 100% open-source & memproses semua data di perangkatmu tanpa server luar. Untuk memantau feed dan menampilkan overlay, aktifkan 3 izin berikut:';

  @override
  String get permAccessibilityTitle =>
      '1. Layanan Aksesibilitas (Accessibility)';

  @override
  String get permAccessibilityDesc =>
      'Mendeteksi saat membuka Reels/TikTok/Shorts dan menghitung jumlah scrolling.';

  @override
  String get permOverlayTitle => '2. Tampilan di Atas Aplikasi Lain (Overlay)';

  @override
  String get permOverlayDesc =>
      'Menampilkan floating scrolling counter dan layer intervensi lembut saat batas tercapai.';

  @override
  String get permBatteryTitle => '3. Nonaktifkan Optimasi Baterai';

  @override
  String get permBatteryDesc =>
      'Menjaga tracker tetap aktif di background tanpa dimatikan paksa oleh sistem HP.';

  @override
  String get grantPermissionBtn => 'Aktifkan Izin';

  @override
  String get permissionGrantedBadge => 'Aktif';

  @override
  String get startProtectingBtn => 'Mulai Lindungi Fokus Saya 🌱';

  @override
  String get continueToDashboardBtn => 'Lanjut ke Dashboard';

  @override
  String get overlayTitle => 'Reclaim Your Time';

  @override
  String get overlayDefaultAffirmation =>
      'Udah cukup ya, mata lu butuh istirahat. Tarik napas perlahan dan kembali ke dunia nyata.';

  @override
  String overlayStatsCount(int count, String appName) =>
      '$count scroll di $appName';

  @override
  String get overlayCloseAppBtn => 'Tutup Aplikasi (Istirahat Dulu)';

  @override
  String get overlaySnoozeBtn => 'Jeda 5 Menit';

  @override
  String get overlaySuccessSnackbar =>
      'Intervensi berhasil: Waktu diselamatkan! 🌱';

  @override
  List<String> get affirmations => const [
    'Udah cukup ya, mata lu butuh istirahat. Tarik napas dulu.',
    'Dunia nyata jauh lebih berharga daripada endless scrolling.',
    'Kendalikan jempolmu, jangan biarkan algoritma mendikte harimu.',
    'Satu napas dalam bernilai lebih dari 100 video singkat.',
    'Waktu yang kamu hemat sekarang adalah energi untuk mimpimu.',
    'Kamu yang memegang kendali. Letakkan ponsel dan istirahatkan pikiranmu.',
  ];
}

/// Flutter Localizations Delegate
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'id'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'id':
        return AppLocalizationsId();
      case 'en':
      default:
        return AppLocalizationsEn();
    }
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

/// Convenient extension on BuildContext
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
