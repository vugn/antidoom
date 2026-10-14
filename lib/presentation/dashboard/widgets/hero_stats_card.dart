import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/scroll_stat.dart';

class HeroStatsCard extends StatelessWidget {
  final ScrollStat stats;
  final bool isTrackingActive;

  const HeroStatsCard({
    super.key,
    required this.stats,
    required this.isTrackingActive,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF14241C), Color(0xFF1A232D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isTrackingActive
              ? AppColors.zenGreen.withValues(alpha: 0.4)
              : AppColors.border,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isTrackingActive
                ? AppColors.zenGreen.withValues(alpha: 0.08)
                : Colors.black26,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.zenGreenSubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: AppColors.zenGreenLight,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.heroTodayAchievement,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.today,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Main Big Metric: Scroll Count
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${stats.todayScrollCount}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.heroScrollsMonitored(stats.todayScrollCount),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 18),

          // Sub Metrics
          Row(
            children: [
              // Saved Time
              Expanded(
                child: _buildSubStat(
                  icon: Icons.timer_outlined,
                  color: AppColors.zenGreenLight,
                  label: l10n.heroTimeSavedLabel,
                  value: l10n.heroTimeSavedValue(stats.todaySavedMinutes),
                ),
              ),
              Container(
                height: 38,
                width: 1,
                color: AppColors.border,
              ),
              // Saved Interventions
              Expanded(
                child: _buildSubStat(
                  icon: Icons.energy_savings_leaf_outlined,
                  color: AppColors.softAmber,
                  label: l10n.heroInterventionsLabel,
                  value: l10n.heroInterventionsValue(stats.todayInterventions),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubStat({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
