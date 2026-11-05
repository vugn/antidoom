import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:antidoom/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pump a fixed amount of time, letting async prefs writes complete.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  testWidgets('Home shows status; language switches from Settings', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(() => tester.view.resetPhysicalSize());

    SharedPreferences.setMockInitialValues({});
    const channel = MethodChannel('com.antidoom/native');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'checkPermissions':
          return {'accessibility': true, 'batteryOptimization': true};
        case 'getNativeStats':
          return {'isTracking': false, 'perAppScrolls': <String, int>{}};
        case 'getAppInfo':
          return <String, dynamic>{};
        default:
          return true;
      }
    });
    addTearDown(() =>
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));

    await tester.pumpWidget(
      const ProviderScope(child: AntiDoomApp(isOnboardingDone: true)),
    );
    await settle(tester);

    expect(find.text('AntiDoom'), findsOneWidget);
    expect(find.text('Protection is off'), findsOneWidget);
    expect(find.text('Swipes today'), findsOneWidget);

    // Open Settings and switch to Indonesian
    await tester.tap(find.byIcon(CupertinoIcons.slider_horizontal_3));
    await settle(tester);
    expect(find.text('Settings'), findsOneWidget);

    await tester.ensureVisible(find.text('Language'));
    await settle(tester);
    await tester.tap(find.text('Language'));
    await settle(tester);
    await tester.tap(find.text('Bahasa Indonesia').last);
    await settle(tester);
    expect(find.text('Umum'), findsOneWidget);

    // Back home: copy is Indonesian
    await tester.tap(find.byIcon(CupertinoIcons.chevron_back));
    await settle(tester);
    expect(find.text('Proteksi mati'), findsOneWidget);
  });
}
