import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/app_rule.dart';
import '../providers/app_state_provider.dart';
import '../widgets/language_selector_sheet.dart';

class BlocklistScreen extends ConsumerWidget {
  const BlocklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final rules = appState.rules;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.blocklistScreenTitle),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: LanguageSwitchButton(compact: true),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Text(
            l10n.blocklistHeading,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.blocklistSubtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          ...rules.map((rule) {
            return _buildRuleCard(context, ref, rule);
          }),

          const SizedBox(height: 16),

          // Privacy Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.zenGreenLight,
                  size: 24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.privacyFirstTitle,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.privacyFirstDesc,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRuleCard(BuildContext context, WidgetRef ref, AppRule rule) {
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: rule.isEnabled ? AppColors.border : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(rule.icon, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule.appName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      rule.category,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: rule.isEnabled,
                onChanged: (val) {
                  ref.read(appStateProvider.notifier).toggleRule(rule.id);
                },
              ),
            ],
          ),
          if (rule.isEnabled) ...[
            const SizedBox(height: 14),
            const Divider(color: AppColors.borderSubtle, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.scrollLimitSliderLabel,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                Text(
                  l10n.scrollLimitValue(rule.scrollLimit),
                  style: const TextStyle(
                    color: AppColors.zenGreenLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Slider(
              value: rule.scrollLimit.toDouble(),
              min: 15,
              max: 150,
              divisions: 27,
              activeColor: AppColors.zenGreen,
              inactiveColor: AppColors.border,
              onChanged: (newVal) {
                ref.read(appStateProvider.notifier).updateRuleLimit(
                      rule.id,
                      newVal.round(),
                      rule.timeLimitMinutes,
                    );
              },
            ),
          ],
        ],
      ),
    );
  }
}
