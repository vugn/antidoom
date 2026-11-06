import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../services/native_bridge.dart';
import '../dashboard/dashboard_screen.dart';
import '../../services/monetization/monetization.dart';
import '../providers/app_state_provider.dart';
import '../widgets/accessibility_disclosure_sheet.dart';
import '../widgets/glass_widgets.dart';

/// The permission steps, with plain-language copy: accessibility and battery
/// everywhere, plus auto-start and (MIUI) background pop-ups on phones whose
/// vendor kills background apps. Used by the first-run setup and by
/// Settings > Permissions.
class PermissionSteps extends ConsumerStatefulWidget {
  const PermissionSteps({super.key});

  @override
  ConsumerState<PermissionSteps> createState() => _PermissionStepsState();
}

class _PermissionStepsState extends ConsumerState<PermissionSteps>
    with WidgetsBindingObserver {
  /// Vendor screen the user was sent to and has not come back from yet.
  String? _pendingOem;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final kind = _pendingOem;
    if (state != AppLifecycleState.resumed || kind == null) return;
    _pendingOem = null;
    _afterOemScreen(kind);
  }

  Future<void> _openOem(String kind) async {
    final opened = await NativeBridge.openOemPermission(kind);
    if (!mounted) return;
    if (opened) {
      _pendingOem = kind;
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.s.oemOpenFailed)));
    }
  }

  /// Back from a vendor screen: re-read what we can, ask about what we can't.
  Future<void> _afterOemScreen(String kind) async {
    final notifier = ref.read(appStateProvider.notifier);
    await notifier.refreshPermissions();
    final perms = ref.read(appStateProvider).permissions;
    if (!mounted || (perms['${kind}Checkable'] ?? false) || (perms[kind] ?? false)) return;

    final s = context.s;
    final yes = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(s.oemConfirmTitle),
        content: Text(s.oemConfirmBody),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.oemConfirmNo),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s.oemConfirmYes),
          ),
        ],
      ),
    );
    if (yes == true) {
      await NativeBridge.confirmOemPermission(kind, true);
      await notifier.refreshPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(appStateProvider);
    final s = context.s;
    final p = context.palette;

    Widget step({
      required int n,
      required String title,
      required String desc,
      required bool done,
      required VoidCallback onAllow,
    }) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Panel(
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? p.accent : p.surface2,
                ),
                alignment: Alignment.center,
                child: done
                    ? const Icon(CupertinoIcons.checkmark_alt,
                        color: Colors.white, size: 20)
                    : Text(
                        '$n',
                        style: TextStyle(
                          color: p.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: p.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      style: TextStyle(color: p.text2, fontSize: 13.5, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              done
                  ? Text(
                      s.doneLabel,
                      style: TextStyle(
                        color: p.accent,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : CupertinoButton(
                      color: p.text,
                      borderRadius: BorderRadius.circular(20),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      minimumSize: const Size(0, 38),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        onAllow();
                      },
                      child: Text(
                        s.allowBtn,
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
      );
    }

    return Column(
      children: [
        step(
          n: 1,
          title: s.stepAccessTitle,
          desc: s.stepAccessDesc,
          done: st.permissions['accessibility'] ?? false,
          // Play policy: show the prominent disclosure and get an explicit
          // "Agree" before sending the user to Android's Accessibility settings.
          onAllow: () async {
            if (await AccessibilityDisclosureSheet.show(context)) {
              await NativeBridge.requestAccessibilityPermission();
            }
          },
        ),
        step(
          n: 2,
          title: s.stepBatteryTitle,
          desc: s.stepBatteryDesc,
          done: st.permissions['batteryOptimization'] ?? false,
          onAllow: NativeBridge.requestBatteryOptimization,
        ),
        if (st.permissions['autostartNeeded'] ?? false)
          step(
            n: 3,
            title: s.stepAutostartTitle,
            desc: s.stepAutostartDesc,
            done: st.permissions['autostart'] ?? false,
            onAllow: () => _openOem('autostart'),
          ),
        if (st.permissions['popupNeeded'] ?? false)
          step(
            n: (st.permissions['autostartNeeded'] ?? false) ? 4 : 3,
            title: s.stepPopupTitle,
            desc: s.stepPopupDesc,
            done: st.permissions['popup'] ?? false,
            onAllow: () => _openOem('popup'),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(36, 16, 36, 0),
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
    );
  }
}

/// Settings > Permissions: just the steps, re-checked whenever the user
/// comes back from system settings.
class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(appStateProvider.notifier).refreshPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final p = context.palette;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemStyleFor(context),
      child: Scaffold(
        body: Stack(
          children: [
            ListView(
              padding: EdgeInsets.only(
                top: FloatingTopBar.heightOf(context) + 8,
                bottom: MediaQuery.paddingOf(context).bottom + 24,
              ),
              physics: const BouncingScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 10),
                  child: Text(s.permissions,
                      style: AppTheme.display(size: 40, color: p.text)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: Text(
                    s.setupScreenDesc,
                    style: TextStyle(color: p.text2, fontSize: 17, height: 1.4),
                  ),
                ),
                const PermissionSteps(),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FloatingTopBar(
                leading: GlassButton(
                  icon: CupertinoIcons.chevron_back,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
