import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/localization/strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';

/// Google Play "prominent disclosure" for the Accessibility Service: says what
/// is read, why, and what stays private, and asks for an explicit "Agree"
/// before Android's Accessibility settings are opened. Closing the sheet or
/// tapping "No thanks" is not consent.
class AccessibilityDisclosureSheet extends StatelessWidget {
  const AccessibilityDisclosureSheet({super.key});

  /// True only when the user tapped "Agree and continue".
  static Future<bool> show(BuildContext context) async {
    final agreed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const AccessibilityDisclosureSheet(),
    );
    return agreed == true;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final p = context.palette;

    Widget point(IconData icon, String title, String body) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: p.surface2,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: p.text, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: p.text, fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(body,
                      style: TextStyle(color: p.text2, fontSize: 14, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.a11yDisclosureTitle, style: AppTheme.display(size: 28, color: p.text)),
              const SizedBox(height: 10),
              Text(s.a11yDisclosureIntro,
                  style: TextStyle(color: p.text2, fontSize: 15, height: 1.4)),
              const SizedBox(height: 22),
              point(CupertinoIcons.eye, s.a11yReadsTitle, s.a11yReadsBody),
              point(CupertinoIcons.scope, s.a11yWhyTitle, s.a11yWhyBody),
              point(CupertinoIcons.lock_shield, s.a11yPrivateTitle, s.a11yPrivateBody),
              point(CupertinoIcons.slider_horizontal_3, s.a11yControlTitle, s.a11yControlBody),
              const SizedBox(height: 6),
              CupertinoButton(
                color: p.text,
                borderRadius: BorderRadius.circular(14),
                padding: const EdgeInsets.symmetric(vertical: 15),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(s.a11yAgree,
                    style: TextStyle(color: p.bg, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 4),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 13),
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(s.a11yDecline,
                    style: TextStyle(color: p.text2, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
