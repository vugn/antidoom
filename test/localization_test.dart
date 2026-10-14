import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:antidoom/core/localization/app_localizations.dart';

void main() {
  group('AppLocalizations Tests', () {
    test('Default English (Dominant) translations have correct texts', () {
      final l10nEn = AppLocalizationsEn();

      expect(l10nEn.currentLanguageCode, 'en');
      expect(l10nEn.appName, 'AntiDoom');
      expect(l10nEn.active, 'ACTIVE');
      expect(l10nEn.inactive, 'INACTIVE');
      expect(l10nEn.masterActiveTitle, contains('Protection Active'));
      expect(l10nEn.masterPausedTitle, contains('Protection Paused'));
      expect(l10nEn.heroTodayAchievement, "Today's Achievements");
      expect(l10nEn.heroScrollsMonitored(10), 'scrolls monitored');
      expect(l10nEn.heroTimeSavedValue(15), '15 min');
      expect(l10nEn.heroInterventionsValue(3), '3 times');
      expect(l10nEn.floatingCounterTitle, 'Floating Scroll Counter');
      expect(l10nEn.targetAppsBtn, 'Target Apps');
      expect(l10nEn.overlayTitle, 'Reclaim Your Time');
      expect(l10nEn.overlayCloseAppBtn, 'Close App (Take a Break)');
      expect(l10nEn.overlaySnoozeBtn, 'Snooze 5 Minutes');
      expect(l10nEn.affirmations.isNotEmpty, true);
    });

    test('Indonesian translations have correct texts', () {
      final l10nId = AppLocalizationsId();

      expect(l10nId.currentLanguageCode, 'id');
      expect(l10nId.appName, 'AntiDoom');
      expect(l10nId.active, 'AKTIF');
      expect(l10nId.inactive, 'NONAKTIF');
      expect(l10nId.masterActiveTitle, contains('Proteksi AntiDoom Aktif'));
      expect(l10nId.masterPausedTitle, contains('Proteksi AntiDoom Jeda'));
      expect(l10nId.heroTodayAchievement, 'Pencapaian Hari Ini');
      expect(l10nId.heroScrollsMonitored(10), 'scrolls terpantau');
      expect(l10nId.heroTimeSavedValue(15), '15 mnt');
      expect(l10nId.heroInterventionsValue(3), '3 kali');
      expect(l10nId.floatingCounterTitle, 'Floating Scroll Counter');
      expect(l10nId.targetAppsBtn, 'Atur Target App');
      expect(l10nId.overlayTitle, 'Reclaim Your Time');
      expect(l10nId.overlayCloseAppBtn, 'Tutup Aplikasi (Istirahat Dulu)');
      expect(l10nId.overlaySnoozeBtn, 'Jeda 5 Menit');
      expect(l10nId.affirmations.isNotEmpty, true);
    });

    test('AppLocalizationsDelegate supports en and id', () {
      const delegate = AppLocalizationsDelegate();

      expect(delegate.isSupported(const Locale('en')), true);
      expect(delegate.isSupported(const Locale('id')), true);
      expect(delegate.isSupported(const Locale('fr')), false);
    });

    test('AppLocalizationsDelegate loads correct instance based on locale', () async {
      const delegate = AppLocalizationsDelegate();

      final enInstance = await delegate.load(const Locale('en'));
      expect(enInstance, isA<AppLocalizationsEn>());
      expect(enInstance.currentLanguageCode, 'en');

      final idInstance = await delegate.load(const Locale('id'));
      expect(idInstance, isA<AppLocalizationsId>());
      expect(idInstance.currentLanguageCode, 'id');
    });
  });
}
