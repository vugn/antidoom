import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/localization/strings.dart';
import '../../core/theme/app_theme.dart';

/// In-app preview of the native break screen. Mirrors the colors and copy of
/// the overlay drawn by the accessibility service (always dark).
class OverlayPreviewDialog extends StatelessWidget {
  final String appName;
  final int scrollCount;
  final String? message;

  const OverlayPreviewDialog({
    super.key,
    this.appName = 'Instagram',
    this.scrollCount = 50,
    this.message,
  });

  static Future<void> show(
    BuildContext context, {
    String appName = 'Instagram',
    int scrollCount = 50,
    String? message,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Break screen preview',
      barrierColor: const Color(0xF20A0A0B),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, _, _) => OverlayPreviewDialog(
        appName: appName,
        scrollCount: scrollCount,
        message: message,
      ),
      transitionBuilder: (context, anim, _, child) {
        final c = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: c,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(c),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = Localizations.localeOf(context).languageCode == 'id';
    const text = Color(0xFFF5F5F4);
    const text2 = Color(0xFF9A9A96);
    const accent = Color(0xFF32D583);

    Widget button(String label, Color bg, Color fg) => SizedBox(
          width: double.infinity,
          height: 52,
          child: CupertinoButton(
            color: bg,
            borderRadius: BorderRadius.circular(26),
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              label,
              style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        );

    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          decoration: BoxDecoration(
            color: const Color(0xFF161618),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF2A2A2E)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                id ? 'Masih mau lanjut?' : 'Still worth it?',
                textAlign: TextAlign.center,
                style: AppTheme.display(size: 28, color: text),
              ),
              const SizedBox(height: 10),
              if (message != null)
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: text2, fontSize: 15, height: 1.45),
                ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2A1C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  id
                      ? '$scrollCount swipe berturut-turut'
                      : '$scrollCount swipes in a row',
                  style: const TextStyle(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              button(id ? 'Berhenti di sini' : 'Stop here', text, const Color(0xFF0A0A0B)),
              const SizedBox(height: 10),
              button(id ? 'Lanjut' : 'Keep going', const Color(0xFF222225), text),
              const SizedBox(height: 4),
              button(id ? 'Jeda sampai besok' : 'Snooze for today', Colors.transparent, text2),
              const SizedBox(height: 4),
              Text(
                context.s.previewBreak,
                style: const TextStyle(color: Color(0xFF5E5E5B), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
