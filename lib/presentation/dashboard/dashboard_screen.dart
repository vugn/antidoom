import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/social_apps.dart';
import '../../core/localization/strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../onboarding/onboarding_screen.dart';
import '../providers/app_state_provider.dart';
import '../../services/monetization/monetization.dart';
import '../settings/blocklist_screen.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/brand.dart';

/// Home: one ring (swipes in a row vs. the limit), one switch, today's numbers.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static void openSetup(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (ctx) => OnboardingScreen(onComplete: () => Navigator.of(ctx).pop()),
      ),
    );
  }

  static void openSettings(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => const BlocklistScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(appStateProvider);
    final installed = ref.watch(installedAppsProvider).value ?? const {};
    final notifier = ref.read(appStateProvider.notifier);
    final s = context.s;
    final p = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final today = st.stats.todayScrollCount;
    final blockAt = st.forceBlockAt;
    final every = st.warnEvery;
    final warnEvery = st.warnEnabled ? every : 0;
    final snoozed = st.snoozedToday;
    final blocked = blockAt > 0 && today >= blockAt && !snoozed;
    // Ring: progress to the hard block if set, else to the next check-in.
    final double progress;
    final String ringSub;
    final String explainer;
    if (blockAt > 0) {
      progress = today / blockAt;
      ringSub = s.sessionOf(blockAt);
      explainer = blocked ? s.blockedToday : s.explainBlock(blockAt, warnEvery);
    } else if (warnEvery > 0) {
      progress = (today % warnEvery) / warnEvery;
      ringSub = s.nextCheckIn((today ~/ warnEvery + 1) * warnEvery);
      explainer = s.explainWarn(warnEvery);
    } else {
      progress = 0;
      ringSub = '';
      explainer = s.explainCountOnly;
    }
    final ringColor = !st.isTrackingActive || snoozed
        ? p.text3
        : blocked
            ? p.danger
            : progress > 0.8
                ? p.warning
                : p.accent;
    final watching = st.rules.where((r) => r.isEnabled).length;
    final monetization = ref.watch(monetizationProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _systemStyle(dark),
      child: Scaffold(
        body: Stack(
          children: [
            RefreshIndicator(
              color: p.accent,
              edgeOffset: FloatingTopBar.heightOf(context),
              onRefresh: notifier.syncFromNative,
              child: ListView(
                padding: EdgeInsets.only(
                  top: FloatingTopBar.heightOf(context),
                  bottom: MediaQuery.paddingOf(context).bottom + 32,
                ),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                children: [
                  // ---- Ring
                  SizedBox(
                    height: 300,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 360,
                          height: 360,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                ringColor.withValues(alpha: dark ? 0.20 : 0.16),
                                ringColor.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                        ProgressRing(
                          value: progress,
                          color: ringColor,
                          track: p.text.withValues(alpha: 0.07),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              bigNumber(context, '$today', size: 76),
                              const SizedBox(height: 2),
                              if (ringSub.isNotEmpty)
                              Text(
                                ringSub,
                                style: TextStyle(
                                  color: p.text2,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                s.swipesTodayCaption,
                                style: TextStyle(color: p.text3, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(48, 4, 48, 28),
                    child: Text(
                      explainer,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.text2, fontSize: 15, height: 1.4),
                    ),
                  ),

                  // ---- Snoozed for today
                  if (snoozed)
                    _pad(
                      Panel(
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.moon_fill, color: p.text2, size: 24),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.snoozedTitle,
                                    style: TextStyle(
                                      color: p.text,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s.snoozedDesc,
                                    style: TextStyle(color: p.text2, fontSize: 13.5),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            CupertinoButton(
                              color: p.text,
                              borderRadius: BorderRadius.circular(20),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              minimumSize: const Size(0, 38),
                              onPressed: notifier.resumeToday,
                              child: Text(
                                s.resumeBtn,
                                style: TextStyle(
                                  color: p.bg,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ---- Setup needed
                  if (!st.areAllPermissionsGranted)
                    _pad(
                      Panel(
                        color: p.warning.withValues(alpha: dark ? 0.14 : 0.12),
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.exclamationmark_circle_fill,
                                color: p.warning, size: 28),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.setupTitle,
                                    style: TextStyle(
                                      color: p.text,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s.setupDesc,
                                    style: TextStyle(color: p.text2, fontSize: 13.5),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            CupertinoButton(
                              color: p.text,
                              borderRadius: BorderRadius.circular(20),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              minimumSize: const Size(0, 38),
                              onPressed: () => openSetup(context),
                              child: Text(
                                s.continueBtn,
                                style: TextStyle(
                                  color: p.bg,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ---- Protection switch
                  _pad(
                    Panel(
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: st.isTrackingActive ? p.accent : p.text3,
                              boxShadow: st.isTrackingActive
                                  ? [
                                      BoxShadow(
                                        color: p.accent.withValues(alpha: 0.5),
                                        blurRadius: 10,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  st.isTrackingActive ? s.protectionOn : s.protectionOff,
                                  style: TextStyle(
                                    color: p.text,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  st.isTrackingActive
                                      ? s.watchingApps(watching)
                                      : s.turnOnHint,
                                  style: TextStyle(color: p.text2, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          AccentSwitch(
                            value: st.isTrackingActive,
                            onChanged: notifier.toggleTracking,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ---- Today's numbers
                  _pad(
                    Panel(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            _stat(context, s.statToday, '${st.stats.todayScrollCount}'),
                            VerticalDivider(width: 1, thickness: 0.5, color: p.line),
                            _stat(context, s.statBreaks, '${st.stats.todayInterventions}'),
                            VerticalDivider(width: 1, thickness: 0.5, color: p.line),
                            _stat(context, s.statSaved,
                                s.minutesShort(st.stats.todaySavedMinutes)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ---- Per app
                  GroupLabel(s.swipesToday),
                  _pad(
                    RowList(
                      children: [
                        for (final rule in st.rules)
                          if (SocialApp.forPackage(rule.packageName) case final app?)
                            Builder(builder: (context) {
                              final count = app.packages.fold<int>(
                                  0, (n, pkg) => n + (st.stats.perAppScrolls[pkg] ?? 0));
                              final isInstalled = installed.isEmpty ||
                                  app.packages.any(installed.containsKey);
                              return ListRow(
                                leading: AppLogo(
                                  app: app,
                                  dimmed: !rule.isEnabled || !isInstalled,
                                ),
                                title: app.name,
                                subtitle: !isInstalled
                                    ? s.notInstalled
                                    : !rule.isEnabled
                                        ? s.paused
                                        : null,
                                trailing: Text(
                                  '$count',
                                  style: AppTheme.display(
                                    size: 20,
                                    weight: FontWeight.w600,
                                    color: count == 0 ? p.text3 : p.text,
                                  ),
                                ),
                                onTap: () => openSettings(context),
                              );
                            }),
                      ],
                    ),
                  ),

                  // ---- Ad (play build only; nothing in foss or after "Remove ads")
                  ListenableBuilder(
                    listenable: monetization,
                    builder: (context, _) => monetization.banner(context),
                  ),
                ],
              ),
            ),

            // ---- Floating glass top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FloatingTopBar(
                title: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ListenableBuilder(
                      listenable: monetization,
                      builder: (context, _) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const BrandWordmark(height: 21),
                          // Supporter mark: the one thing the purchase adds besides no ads.
                          if (monetization.isSupporter) ...[
                            const SizedBox(width: 8),
                            Tooltip(
                              message: s.supporterBadge,
                              child: Icon(CupertinoIcons.heart_fill, color: p.danger, size: 18),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  GlassButton(
                    icon: CupertinoIcons.slider_horizontal_3,
                    tooltip: s.settingsTitle,
                    onTap: () => openSettings(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _pad(Widget child) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: child,
      );

  static Widget _stat(BuildContext context, String label, String value) {
    final p = context.palette;
    return Expanded(
      child: Column(
        children: [
          bigNumber(context, value, size: 30),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: p.text2, fontSize: 13)),
        ],
      ),
    );
  }
}

SystemUiOverlayStyle _systemStyle(bool dark) => SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    );

SystemUiOverlayStyle systemStyleFor(BuildContext context) =>
    _systemStyle(Theme.of(context).brightness == Brightness.dark);
