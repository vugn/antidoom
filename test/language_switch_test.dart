import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:antidoom/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App starts with dominant English and switches to Indonesian seamlessly',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: AntiDoomApp(isOnboardingDone: true),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial English texts appear (Dominant / Default)
    expect(find.text('Break the Loop • Reclaim Time'), findsOneWidget);
    expect(find.text("Today's Achievements"), findsOneWidget);
    expect(find.text('Floating Scroll Counter'), findsOneWidget);
    expect(find.text('Target Apps'), findsOneWidget);

    // Find and tap the language switch button (EN)
    final langBtn = find.text('EN');
    expect(langBtn, findsOneWidget);
    await tester.tap(langBtn);
    await tester.pumpAndSettle();

    // The language bottom sheet should be visible with Indonesian option
    final idOption = find.text('Bahasa Indonesia');
    expect(idOption, findsOneWidget);
    await tester.tap(idOption);
    await tester.pumpAndSettle();

    // Verify UI has updated dynamically to Indonesian
    expect(find.text('Pencapaian Hari Ini'), findsOneWidget);
    expect(find.text('Atur Target App'), findsOneWidget);
    expect(find.text('ID'), findsOneWidget);

    // Switch back to English
    final idLangBtn = find.text('ID');
    await tester.tap(idLangBtn);
    await tester.pumpAndSettle();

    final enOption = find.text('English');
    expect(enOption, findsOneWidget);
    await tester.tap(enOption);
    await tester.pumpAndSettle();

    // Verify English returns
    expect(find.text("Today's Achievements"), findsOneWidget);
    expect(find.text('Target Apps'), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);
  });
}
