import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'app_palette.dart';

class AppTheme {
  static ThemeData get lightTheme => _build(Brightness.light, AppPalette.light);
  static ThemeData get darkTheme => _build(Brightness.dark, AppPalette.dark);

  /// Bundled font families (see pubspec.yaml); nothing is fetched at runtime.
  static const String fontText = 'Inter';
  static const String fontDisplay = 'InterTight';

  /// Display face for big numbers and titles.
  static TextStyle display({
    required double size,
    required Color color,
    FontWeight weight = FontWeight.w700,
  }) {
    return TextStyle(
      fontFamily: fontDisplay,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: -size * 0.035,
      height: 1.05,
      fontFeatures: const [FontFeature.tabularFigures()],
    ).copyWith(fontFamilyFallback: const ['Roboto']);
  }

  static ThemeData _build(Brightness brightness, AppPalette p) {
    final base =
        brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light();
    final textTheme = base.textTheme.apply(
      fontFamily: fontText,
      bodyColor: p.text,
      displayColor: p.text,
      fontFamilyFallback: const ['Roboto'],
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      primaryColor: p.accent,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: p.accent,
        onPrimary: Colors.white,
        secondary: p.accent,
        onSecondary: Colors.white,
        error: p.danger,
        onError: Colors.white,
        surface: p.surface,
        onSurface: p.text,
      ),
      fontFamily: fontText,
      textTheme: textTheme,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerColor: p.line,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      cupertinoOverrideTheme: NoDefaultCupertinoThemeData(
        brightness: brightness,
        primaryColor: p.accent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.bg,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: p.text3,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      extensions: [p],
    );
  }
}
