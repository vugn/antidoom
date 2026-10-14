import 'package:flutter/material.dart';

/// AntiDoom Zen Design System Color Palette
/// Designed to reduce visual overstimulation and induce calm mindfulness.
class AppColors {
  // Brand & Zen Accents
  static const Color zenGreen = Color(0xFF27AE60);
  static const Color zenGreenLight = Color(0xFF2ECC71);
  static const Color zenGreenSubtle = Color(0xFF143825);
  static const Color deepIndigo = Color(0xFF2C3E50);

  // Status & Alerts
  static const Color softAmber = Color(0xFFF39C12);
  static const Color amberSubtle = Color(0xFF382A12);
  static const Color coralRed = Color(0xFFE74C3C);
  static const Color coralSubtle = Color(0xFF3B1A17);

  // Backgrounds (Dark Mode First / AMOLED Friendly)
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1A232D);
  static const Color surfaceElevated = Color(0xFF212D3A);
  static const Color surfaceHover = Color(0xFF2B3A4A);

  // Typography
  static const Color textPrimary = Color(0xFFF5F6FA);
  static const Color textSecondary = Color(0xFFBDC3C7);
  static const Color textMuted = Color(0xFF7F8C8D);

  // Dividers & Borders
  static const Color border = Color(0xFF2C3A47);
  static const Color borderSubtle = Color(0xFF1E2832);

  // Gradients
  static const LinearGradient zenGradient = LinearGradient(
    colors: [Color(0xFF27AE60), Color(0xFF1E824C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1A232D), Color(0xFF161C24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFF39C12), Color(0xFFD35400)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
