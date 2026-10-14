import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/app_repository.dart';
import '../../services/native_bridge.dart';
import '../../presentation/providers/app_state_provider.dart';

class LocaleNotifier extends Notifier<Locale> {
  late final AppRepository _repository;

  @override
  Locale build() {
    _repository = ref.watch(appRepositoryProvider);
    // Initialize saved locale asynchronously
    Future.microtask(() => _loadSavedLocale());
    // Default is English (dominant)
    return const Locale('en');
  }

  Future<void> _loadSavedLocale() async {
    final langCode = await _repository.getLanguageCode();
    final locale = Locale(langCode);
    state = locale;
    // Also notify native side
    NativeBridge.setLanguage(langCode);
  }

  Future<void> setLocale(Locale newLocale) async {
    if (state == newLocale) return;
    state = newLocale;
    await _repository.setLanguageCode(newLocale.languageCode);
    NativeBridge.setLanguage(newLocale.languageCode);
  }

  Future<void> toggleLocale() async {
    final next = state.languageCode == 'en' ? const Locale('id') : const Locale('en');
    await setLocale(next);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});
