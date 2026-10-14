import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/app_repository.dart';
import 'presentation/dashboard/dashboard_screen.dart';
import 'presentation/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI navigation bar & status bar transparent for dark AMOLED look
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF121212),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

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

class _AntiDoomAppState extends ConsumerState<AntiDoomApp> {
  late bool _isOnboardingDone;

  @override
  void initState() {
    super.initState();
    _isOnboardingDone = widget.isOnboardingDone;
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'AntiDoom',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
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
          : OnboardingScreen(
              onComplete: () {
                setState(() {
                  _isOnboardingDone = true;
                });
              },
            ),
    );
  }
}
