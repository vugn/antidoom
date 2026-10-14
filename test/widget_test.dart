import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:antidoom/main.dart';

void main() {
  testWidgets('AntiDoom app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AntiDoomApp(isOnboardingDone: false),
      ),
    );
    await tester.pumpAndSettle();

    // Verify AntiDoom title appears in onboarding
    expect(find.text('AntiDoom'), findsWidgets);
  });
}
