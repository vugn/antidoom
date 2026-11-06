import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/social_apps.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../dashboard/dashboard_screen.dart';
import '../overlay_preview/overlay_preview_dialog.dart';
import '../../services/native_bridge.dart';
import '../providers/app_state_provider.dart';
import '../../services/monetization/monetization.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/brand.dart';
import '../widgets/language_selector_sheet.dart';

/// Settings: limit, apps, and everything else, on one page.
class BlocklistScreen extends ConsumerWidget {
  const BlocklistScreen({super.key});

  static int _previewStep = -1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(appStateProvider);
    final installed = ref.watch(installedAppsProvider).value ?? const {};
    final notifier = ref.read(appStateProvider.notifier);
    final s = context.s;
    final p = context.palette;

    Future<void> editBlock() async {
      final v = await showNumberSheet(
        context,
        title: s.hardBlockSheetTitle,
        hint: s.hardBlockSheetHint,
        saveLabel: s.save,
        errorText: s.invalidNumber,
        initial: st.forceBlockAt > 0 ? st.forceBlockAt : null,
      );
      if (v != null) await notifier.setForceBlockAt(v);
    }

    Future<void> editWarn() async {
      final v = await showNumberSheet(
        context,
        title: s.checkInSheetTitle,
        hint: s.checkInSheetHint,
        saveLabel: s.save,
        errorText: s.invalidCheckIn,
        initial: st.warnEvery,
        min: 10,
        max: 1000,
        placeholder: '100',
      );
      if (v != null) await notifier.setWarnEvery(v);
    }

    Widget valueRow(String title, int value, VoidCallback onTap) => ListRow(
          leading: const SizedBox(width: 38),
          title: title,
          trailing: Text(
            s.swipesValue(value),
            style: TextStyle(
              color: p.accent,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          chevron: true,
          onTap: onTap,
        );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemStyleFor(context),
      child: Scaffold(
        body: Stack(
          children: [
            ListView(
              padding: EdgeInsets.only(
                top: FloatingTopBar.heightOf(context),
                bottom: MediaQuery.paddingOf(context).bottom + 40,
              ),
              physics: const BouncingScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 4, 28, 0),
                  child: Text(s.settingsTitle,
                      style: AppTheme.display(size: 40, color: p.text)),
                ),

                // ---- When to stop
                GroupLabel(s.whenToStop),
                _pad(
                  RowList(
                    children: [
                      ListRow(
                        leading: IconTile(
                            icon: CupertinoIcons.hand_raised_fill, color: p.warning),
                        title: s.checkInTitle,
                        subtitle: s.checkInDesc,
                        trailing: AccentSwitch(
                          value: st.warnEnabled,
                          onChanged: notifier.setWarnEnabled,
                        ),
                      ),
                      if (st.warnEnabled)
                        valueRow(s.checkInEveryLabel, st.warnEvery, editWarn),
                      ListRow(
                        leading: IconTile(
                            icon: CupertinoIcons.lock_fill, color: p.danger),
                        title: s.hardBlockTitle,
                        subtitle: st.forceBlockAt > 0 ? s.hardBlockDesc : s.paused,
                        trailing: AccentSwitch(
                          value: st.forceBlockAt > 0,
                          onChanged: (on) =>
                              on ? editBlock() : notifier.setForceBlockAt(0),
                        ),
                      ),
                      if (st.forceBlockAt > 0)
                        valueRow(s.blockAfterRow, st.forceBlockAt, editBlock),
                    ],
                  ),
                ),

                // ---- Apps
                GroupLabel(s.appsToWatch),
                _pad(
                  RowList(
                    children: [
                      for (final rule in st.rules)
                        if (SocialApp.forPackage(rule.packageName) case final app?)
                          Builder(builder: (context) {
                            final isInstalled = installed.isEmpty ||
                                app.packages.any(installed.containsKey);
                            return ListRow(
                              leading: AppLogo(app: app, dimmed: !isInstalled),
                              title: app.name,
                              subtitle: isInstalled ? null : s.notInstalled,
                              trailing: AccentSwitch(
                                value: rule.isEnabled,
                                onChanged: (_) => notifier.toggleRule(rule.id),
                              ),
                            );
                          }),
                    ],
                  ),
                ),

                // ---- General
                GroupLabel(s.general),
                _pad(
                  RowList(
                    children: [
                      ListRow(
                        leading: IconTile(
                            icon: CupertinoIcons.number_circle_fill, color: p.accent),
                        title: s.floatingCounter,
                        subtitle: s.floatingCounterHint,
                        trailing: AccentSwitch(
                          value: st.isFloatingCounterEnabled,
                          onChanged: notifier.toggleFloatingCounter,
                        ),
                      ),
                      ListRow(
                        leading: const IconTile(
                            icon: CupertinoIcons.globe, color: Color(0xFF2E90FA)),
                        title: s.language,
                        subtitle: s.languageName,
                        chevron: true,
                        onTap: () => LanguageSelectorSheet.show(context),
                      ),
                      ListRow(
                        leading: IconTile(
                          icon: CupertinoIcons.lock_fill,
                          color: st.areAllPermissionsGranted ? p.accent : p.warning,
                        ),
                        title: s.permissions,
                        subtitle: st.areAllPermissionsGranted ? s.allSet : s.needsAction,
                        chevron: true,
                        onTap: () => DashboardScreen.openSetup(context),
                      ),
                      ListRow(
                        leading: const IconTile(
                            icon: CupertinoIcons.eye_fill, color: Color(0xFF7A5AF8)),
                        title: s.previewBreak,
                        chevron: true,
                        onTap: () {
                          final l10n = context.l10n;
                          final message = l10n.getRandomAffirmation();
                          final count = st.stats.todayScrollCount > 0
                              ? st.stats.todayScrollCount
                              : 100;
                          OverlayPreviewDialog.show(
                            context,
                            appName: 'Instagram',
                            scrollCount: count,
                            message: message,
                          );
                        },
                      ),
                      if (kDebugMode)
                        ListRow(
                          leading: IconTile(
                              icon: CupertinoIcons.capsule_fill, color: p.text2),
                          title: 'Preview counter',
                          subtitle: 'Debug: calm → tired → fried',
                          onTap: () {
                            const counts = [36, 78, 96];
                            _previewStep = (_previewStep + 1) % counts.length;
                            NativeBridge.previewCounter(counts[_previewStep]);
                          },
                        ),
                      if (kDebugMode)
                        ListRow(
                          leading: IconTile(
                              icon: CupertinoIcons.hand_draw_fill, color: p.text2),
                          title: s.simulateSwipe,
                          onTap: () =>
                              notifier.simulateScroll('com.instagram.android'),
                        ),
                    ],
                  ),
                ),
                // ---- Support (play build only)
                if (ref.watch(monetizationProvider) case final m when m.hasStore)
                  ListenableBuilder(
                    listenable: m,
                    builder: (context, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GroupLabel(s.support),
                        _pad(
                          RowList(
                            children: [
                              ListRow(
                                leading: IconTile(
                                    icon: CupertinoIcons.heart_fill,
                                    color: m.adsRemoved ? p.accent : p.danger),
                                title: m.adsRemoved ? s.adsRemovedTitle : s.removeAds,
                                subtitle: m.adsRemoved
                                    ? s.adsRemovedDesc
                                    : switch (m.purchaseState) {
                                        PurchaseState.pending => s.purchasePending,
                                        PurchaseState.error => s.purchaseFailed,
                                        PurchaseState.idle => s.removeAdsDesc(m.removeAdsPrice),
                                      },
                                chevron: !m.adsRemoved,
                                onTap: m.adsRemoved || m.purchaseState == PurchaseState.pending
                                    ? null
                                    : m.buyRemoveAds,
                              ),
                              if (!m.adsRemoved)
                                ListRow(
                                  leading: IconTile(
                                      icon: CupertinoIcons.arrow_counterclockwise,
                                      color: p.text2),
                                  title: s.restorePurchase,
                                  onTap: m.restorePurchases,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                // ---- About / open source
                GroupLabel(s.about),
                _pad(
                  RowList(
                    children: [
                      ListRow(
                        leading: IconTile(
                            icon: CupertinoIcons.chevron_left_slash_chevron_right,
                            color: p.text),
                        title: s.viewOnGithub,
                        subtitle: AppConstants.githubUrl.replaceFirst('https://', ''),
                        chevron: true,
                        onTap: () => NativeBridge.openUrl(AppConstants.githubUrl),
                      ),
                      ListRow(
                        leading: const IconTile(
                            icon: CupertinoIcons.doc_text_fill, color: Color(0xFF12B76A)),
                        title: s.licenses,
                        subtitle: s.licensesDesc,
                        chevron: true,
                        onTap: () => showLicensePage(
                          context: context,
                          applicationName: AppConstants.appName,
                          applicationIcon: const Padding(
                            padding: EdgeInsets.all(12),
                            child: BrandSymbol(size: 64, icon: true),
                          ),
                          applicationLegalese:
                              '${AppConstants.copyright}\n${s.openSourceDesc(AppConstants.license)}',
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(36, 14, 36, 0),
                  child: Text(
                    '${AppConstants.copyright} · ${s.openSourceDesc(AppConstants.license)}',
                    style: TextStyle(color: p.text3, fontSize: 13, height: 1.4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(36, 10, 36, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(CupertinoIcons.lock_shield, size: 16, color: p.text3),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ref.watch(monetizationProvider).hasStore ? s.privacyNotePlay : s.privacyNote,
                          style: TextStyle(color: p.text3, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FloatingTopBar(
                leading: GlassButton(
                  icon: CupertinoIcons.chevron_back,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _pad(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: child,
      );
}
