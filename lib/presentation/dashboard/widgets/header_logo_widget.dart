import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/language_selector_sheet.dart';

class HeaderLogoWidget extends StatelessWidget {
  final bool isTrackingActive;
  final VoidCallback onToggleTracking;

  const HeaderLogoWidget({
    super.key,
    required this.isTrackingActive,
    required this.onToggleTracking,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // App Logo Icon
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/images/splash_mark_512.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.zenGreenSubtle,
                child: const Center(
                  child: Text('🛡️', style: TextStyle(fontSize: 22)),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 14),
        // Title & Tagline
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'AntiDoom',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isTrackingActive
                          ? AppColors.zenGreenSubtle
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isTrackingActive
                            ? AppColors.zenGreen.withValues(alpha: 0.5)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isTrackingActive
                                ? AppColors.zenGreenLight
                                : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isTrackingActive ? l10n.active : l10n.inactive,
                          style: TextStyle(
                            color: isTrackingActive
                                ? AppColors.zenGreenLight
                                : AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                l10n.headerTagline,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Language Selector Switch Button
        const LanguageSwitchButton(compact: true),
      ],
    );
  }
}
