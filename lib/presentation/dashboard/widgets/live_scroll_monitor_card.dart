import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

class LiveScrollMonitorCard extends StatelessWidget {
  final bool isTrackingActive;
  final bool isFloatingCounterEnabled;
  final int currentScrolls;
  final int maxScrollLimit;
  final String? activePackage;
  final ValueChanged<bool> onToggleFloatingCounter;
  final VoidCallback onSimulateScroll;
  final VoidCallback onTriggerTestOverlay;

  const LiveScrollMonitorCard({
    super.key,
    required this.isTrackingActive,
    required this.isFloatingCounterEnabled,
    required this.currentScrolls,
    this.maxScrollLimit = 50,
    this.activePackage,
    required this.onToggleFloatingCounter,
    required this.onSimulateScroll,
    required this.onTriggerTestOverlay,
  });

  String _formatPackage(BuildContext context, String? pkg) {
    if (pkg == null || pkg.isEmpty) return context.l10n.readyToDetectFeed;
    if (pkg.contains('instagram')) return 'Instagram (Reels/Feed)';
    if (pkg.contains('musically') || pkg.contains('trill')) return 'TikTok (FYP)';
    if (pkg.contains('youtube')) return 'YouTube (Shorts)';
    if (pkg.contains('twitter')) return 'X (Twitter Timeline)';
    if (pkg.contains('katana')) return 'Facebook';
    return pkg;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progress = (currentScrolls / maxScrollLimit).clamp(0.0, 1.0);
    final isNearLimit = progress > 0.7;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isNearLimit ? AppColors.softAmber : AppColors.border,
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isFloatingCounterEnabled
                          ? AppColors.zenGreenSubtle
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.bubble_chart_outlined,
                      color: isFloatingCounterEnabled
                          ? AppColors.zenGreenLight
                          : AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.floatingCounterTitle,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l10n.floatingCounterDesc,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: isFloatingCounterEnabled,
                onChanged: onToggleFloatingCounter,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Active App Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isTrackingActive ? AppColors.zenGreenLight : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _formatPackage(context, activePackage),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  l10n.scrollsProgress(currentScrolls, maxScrollLimit),
                  style: TextStyle(
                    color: isNearLimit ? AppColors.softAmber : AppColors.zenGreenLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearPercentIndicator(
              lineHeight: 8.0,
              percent: progress,
              padding: EdgeInsets.zero,
              backgroundColor: AppColors.border,
              progressColor: isNearLimit ? AppColors.softAmber : AppColors.zenGreen,
              barRadius: const Radius.circular(8),
            ),
          ),
          const SizedBox(height: 18),

          // Action row for testing & demonstration
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSimulateScroll,
                  icon: const Icon(Icons.touch_app_outlined, size: 16),
                  label: Text(l10n.simulateScrollBtn),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onTriggerTestOverlay,
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: Text(l10n.testInterceptorBtn),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.zenGreenSubtle,
                    foregroundColor: AppColors.zenGreenLight,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.zenGreen, width: 1),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
