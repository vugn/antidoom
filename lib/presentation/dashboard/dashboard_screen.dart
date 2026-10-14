import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../onboarding/onboarding_screen.dart';
import '../overlay_preview/overlay_preview_dialog.dart';
import '../providers/app_state_provider.dart';
import '../settings/blocklist_screen.dart';
import 'widgets/daily_breakdown_card.dart';
import 'widgets/header_logo_widget.dart';
import 'widgets/hero_stats_card.dart';
import 'widgets/live_scroll_monitor_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.zenGreen,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            await notifier.refreshPermissions();
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Top Header with Language Switcher
              HeaderLogoWidget(
                isTrackingActive: appState.isTrackingActive,
                onToggleTracking: () {
                  notifier.toggleTracking(!appState.isTrackingActive);
                },
              ),
              const SizedBox(height: 20),

              // Master Switch Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: appState.isTrackingActive
                        ? AppColors.zenGreen.withValues(alpha: 0.5)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appState.isTrackingActive
                                ? l10n.masterActiveTitle
                                : l10n.masterPausedTitle,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            appState.isTrackingActive
                                ? l10n.masterActiveDesc
                                : l10n.masterPausedDesc,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: appState.isTrackingActive,
                      onChanged: (val) => notifier.toggleTracking(val),
                    ),
                  ],
                ),
              ),

              // Permissions warning banner if any missing
              if (!appState.areAllPermissionsGranted) ...[
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OnboardingScreen(
                          onComplete: () => Navigator.of(context).pop(),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.amberSubtle,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.softAmber.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.softAmber,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.missingPermissionsBanner,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.softAmber,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // Hero Stats Card
              HeroStatsCard(
                stats: appState.stats,
                isTrackingActive: appState.isTrackingActive,
              ),

              const SizedBox(height: 18),

              // Floating Scroll Counter & Live Tracker Card
              LiveScrollMonitorCard(
                isTrackingActive: appState.isTrackingActive,
                isFloatingCounterEnabled: appState.isFloatingCounterEnabled,
                currentScrolls: appState.currentSessionScrolls,
                maxScrollLimit: 50,
                activePackage: appState.currentActivePackage,
                onToggleFloatingCounter: (val) {
                  notifier.toggleFloatingCounter(val);
                },
                onSimulateScroll: () {
                  notifier.simulateScroll('com.instagram.android');
                },
                onTriggerTestOverlay: () {
                  final randomAffirmation = l10n.getRandomAffirmation();
                  final count = appState.currentSessionScrolls > 0
                      ? appState.currentSessionScrolls
                      : 50;

                  // Show in-app preview dialog
                  OverlayPreviewDialog.show(
                    context,
                    appName: 'Instagram',
                    scrollCount: count,
                    message: randomAffirmation,
                  );
                  // Also invoke native test
                  notifier.testTriggerOverlay(
                    appName: 'Instagram',
                    scrollCount: count,
                    message: randomAffirmation,
                  );
                },
              ),

              const SizedBox(height: 18),

              // Daily Breakdown Card
              DailyBreakdownCard(
                rules: appState.rules,
                perAppScrolls: appState.stats.perAppScrolls,
                weeklyHistory: appState.stats.weeklyScrollHistory,
              ),

              const SizedBox(height: 18),

              // Action buttons row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BlocklistScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: Text(l10n.targetAppsBtn),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OnboardingScreen(
                              onComplete: () => Navigator.of(context).pop(),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.security_rounded, size: 18),
                      label: Text(l10n.permissionStatusBtn),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
