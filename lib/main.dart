import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/app_repository.dart';
import 'presentation/dashboard/dashboard_screen.dart';
import 'presentation/onboarding/setup_flow.dart';
import 'presentation/providers/app_state_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // AntiDoom's own MIT license shows up first on Settings > Licenses.
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('LICENSE');
    yield LicenseEntryWithLineBreaks(const ['AntiDoom'], text);
  });
  // Bundled fonts are under the SIL Open Font License.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
        const ['Inter'], await rootBundle.loadString('assets/fonts/inter/OFL.txt'));
    yield LicenseEntryWithLineBreaks(const ['Inter Tight'],
        await rootBundle.loadString('assets/fonts/intertight/OFL.txt'));
  });
  // Precompile glass shaders so the first lens renders correctly
  await LiquidGlassShaders.ensureLoaded();

  final repository = AppRepository();
  final isOnboardingDone = await repository.isOnboardingCompleted();

  runApp(
    ProviderScope(
      child: AntiDoomApp(isOnboardingDone: isOnboardingDone),
    ),
  );
}

class AntiDoomApp extends ConsumerStatefulWidget {
  final bool isOnboardingDone;

  const AntiDoomApp({super.key, required this.isOnboardingDone});

  @override
  ConsumerState<AntiDoomApp> createState() => _AntiDoomAppState();
}

class _AntiDoomAppState extends ConsumerState<AntiDoomApp>
    with WidgetsBindingObserver {
  late bool _isOnboardingDone;

  @override
  void initState() {
    super.initState();
    _isOnboardingDone = widget.isOnboardingDone;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Native keeps counting while we are in the background: re-sync on return
    if (state == AppLifecycleState.resumed) {
      ref.read(appStateProvider.notifier).syncFromNative();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'AntiDoom',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      locale: currentLocale,
      supportedLocales: const [
        Locale('en'),
        Locale('id'),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _isOnboardingDone
          ? const DashboardScreen()
          : SetupFlow(
              onComplete: () {
                setState(() {
                  _isOnboardingDone = true;
                });
              },
            ),
    );
  }
}
