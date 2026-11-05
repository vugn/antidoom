import 'package:flutter/material.dart';

/// Neutral, high-contrast palette with a single green accent.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color line;
  final Color text;
  final Color text2;
  final Color text3;
  final Color accent;
  final Color accentSoft;
  final Color warning;
  final Color danger;

  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.line,
    required this.text,
    required this.text2,
    required this.text3,
    required this.accent,
    required this.accentSoft,
    required this.warning,
    required this.danger,
  });

  static const light = AppPalette(
    bg: Color(0xFFF5F5F2),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFEDEDE9),
    line: Color(0xFFE4E4DF),
    text: Color(0xFF0A0A0A),
    text2: Color(0xFF6B6B66),
    text3: Color(0xFFA3A39E),
    accent: Color(0xFF12B76A),
    accentSoft: Color(0xFFDDF6E8),
    warning: Color(0xFFF79009),
    danger: Color(0xFFF04438),
  );

  static const dark = AppPalette(
    bg: Color(0xFF0A0A0B),
    surface: Color(0xFF161618),
    surface2: Color(0xFF222225),
    line: Color(0xFF2A2A2E),
    text: Color(0xFFF5F5F4),
    text2: Color(0xFF9A9A96),
    text3: Color(0xFF5E5E5B),
    accent: Color(0xFF32D583),
    accentSoft: Color(0xFF0F2A1C),
    warning: Color(0xFFFDB022),
    danger: Color(0xFFF97066),
  );

  @override
  AppPalette copyWith({Color? accent}) => AppPalette(
        bg: bg,
        surface: surface,
        surface2: surface2,
        line: line,
        text: text,
        text2: text2,
        text3: text3,
        accent: accent ?? this.accent,
        accentSoft: accentSoft,
        warning: warning,
        danger: danger,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surface2: l(surface2, other.surface2),
      line: l(line, other.line),
      text: l(text, other.text),
      text2: l(text2, other.text2),
      text3: l(text3, other.text3),
      accent: l(accent, other.accent),
      accentSoft: l(accentSoft, other.accentSoft),
      warning: l(warning, other.warning),
      danger: l(danger, other.danger),
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}
