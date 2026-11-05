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
    await tester.pump(const Duration(milliseconds: 600));

    // Setup screen shows on first launch
    expect(find.text('Choose your language'), findsOneWidget);
  });
}
