import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_colors.dart';

class LanguageSelectorSheet extends ConsumerWidget {
  const LanguageSelectorSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const LanguageSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currentLocale = ref.watch(localeProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.2),
          left: BorderSide(color: AppColors.border, width: 1.2),
          right: BorderSide(color: AppColors.border, width: 1.2),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.zenGreenSubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.language_rounded,
                  color: AppColors.zenGreenLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.selectLanguage,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // English (Dominant / Default)
          _buildLanguageItem(
            context: context,
            title: 'English',
            subtitle: 'Default language',
            flag: '🇬🇧',
            isSelected: currentLocale.languageCode == 'en',
            onTap: () {
              ref.read(localeProvider.notifier).setLocale(const Locale('en'));
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 12),

          // Indonesian
          _buildLanguageItem(
            context: context,
            title: 'Bahasa Indonesia',
            subtitle: 'Bahasa sekunder',
            flag: '🇮🇩',
            isSelected: currentLocale.languageCode == 'id',
            onTap: () {
              ref.read(localeProvider.notifier).setLocale(const Locale('id'));
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String flag,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.zenGreenSubtle : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.zenGreen : AppColors.borderSubtle,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.zenGreenLight,
                size: 22,
              )
            else
              const Icon(
                Icons.radio_button_unchecked,
                color: AppColors.textMuted,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact Language Switcher Pill for headers and bars
class LanguageSwitchButton extends ConsumerWidget {
  final bool compact;

  const LanguageSwitchButton({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isEn = currentLocale.languageCode == 'en';

    return InkWell(
      onTap: () => LanguageSelectorSheet.show(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 5 : 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEn ? '🇬🇧' : '🇮🇩',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(width: 6),
            Text(
              isEn ? 'EN' : 'ID',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
