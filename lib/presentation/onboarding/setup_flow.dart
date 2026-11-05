import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/social_apps.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/localization/strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../dashboard/dashboard_screen.dart';
import '../providers/app_state_provider.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/brand.dart';
import 'onboarding_screen.dart';

enum _StopMode { checkIn, block }

/// First-run setup: language -> apps -> how to stop -> permissions.
class SetupFlow extends ConsumerStatefulWidget {
  final VoidCallback onComplete;
  const SetupFlow({super.key, required this.onComplete});

  @override
  ConsumerState<SetupFlow> createState() => _SetupFlowState();
}

class _SetupFlowState extends ConsumerState<SetupFlow> with WidgetsBindingObserver {
  static const _pages = 4;
  final _pager = PageController();
  final _blockCtrl = TextEditingController(text: '300');
  final _warnCtrl = TextEditingController(text: '100');
  int _page = 0;
  _StopMode _mode = _StopMode.checkIn;
  bool _blockError = false;
  bool _warnError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pager.dispose();
    _blockCtrl.dispose();
    _warnCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from system settings: refresh permission state
    if (state == AppLifecycleState.resumed) {
      ref.read(appStateProvider.notifier).refreshPermissions();
    }
  }

  void _go(int page) {
    FocusScope.of(context).unfocus();
    setState(() => _page = page);
    _pager.animateToPage(
      page,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _next() async {
    final notifier = ref.read(appStateProvider.notifier);
    final st = ref.read(appStateProvider);

    switch (_page) {
      case 2:
        int blockAt = 0;
        if (_mode == _StopMode.block) {
          final v = int.tryParse(_blockCtrl.text);
          if (v == null || v < 10 || v > 5000) {
            HapticFeedback.heavyImpact();
            setState(() => _blockError = true);
            return;
          }
          blockAt = v;
        }
        if (_mode == _StopMode.checkIn) {
          final w = int.tryParse(_warnCtrl.text);
          if (w == null || w < 10 || w > 1000) {
            HapticFeedback.heavyImpact();
            setState(() => _warnError = true);
            return;
          }
          await notifier.setWarnEvery(w);
        } else {
          await notifier.setWarnEnabled(true);
        }
        await notifier.setForceBlockAt(blockAt);
        _go(3);
      case 3:
        await ref.read(appRepositoryProvider).setOnboardingCompleted(true);
        if (st.permissions['accessibility'] ?? false) {
          await notifier.toggleTracking(true);
        }
        widget.onComplete();
      default:
        _go(_page + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(appStateProvider);
    final s = context.s;
    final p = context.palette;
    final accessibility = st.permissions['accessibility'] ?? false;
    final anyApp = st.rules.any((r) => r.isEnabled);

    final label = switch (_page) {
      3 => accessibility ? s.startBtn : s.skipForNow,
      _ => s.continueBtn,
    };
    final canContinue = _page != 1 || anyApp;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemStyleFor(context),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // ---- Back + progress
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: _page > 0
                          ? GlassButton(
                              icon: CupertinoIcons.chevron_back,
                              onTap: () => _go(_page - 1),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        children: [
                          for (var i = 0; i < _pages; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: 4,
                                decoration: BoxDecoration(
                                  color: i <= _page ? p.text : p.surface2,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 60),
                  ],
                ),
              ),

              // ---- Pages
              Expanded(
                child: PageView(
                  controller: _pager,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _languagePage(context),
                    _appsPage(context),
                    _modePage(context),
                    _Page(
                      step: s.stepOf(4, _pages),
                      title: s.obPermTitle,
                      desc: s.setupScreenDesc,
                      padded: false,
                      child: const PermissionSteps(),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: PrimaryButton(
                  label: label,
                  enabled: canContinue,
                  onPressed: _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------

  Widget _languagePage(BuildContext context) {
    final s = context.s;
    final code = ref.watch(localeProvider).languageCode;
    void pick(String c) => ref.read(localeProvider.notifier).setLocale(Locale(c));

    return _Page(
      leading: const BrandWordmark(height: 30),
      step: s.stepOf(1, _pages),
      title: s.obLangTitle,
      desc: s.obLangDesc,
      child: Column(
        children: [
          _Choice(
            badge: 'EN',
            title: 'English',
            selected: code == 'en',
            onTap: () => pick('en'),
          ),
          const SizedBox(height: 12),
          _Choice(
            badge: 'ID',
            title: 'Bahasa Indonesia',
            selected: code == 'id',
            onTap: () => pick('id'),
          ),
        ],
      ),
    );
  }

  Widget _appsPage(BuildContext context) {
    final s = context.s;
    final p = context.palette;
    final st = ref.watch(appStateProvider);
    final installed = ref.watch(installedAppsProvider).value ?? const {};
    final notifier = ref.read(appStateProvider.notifier);

    final items = [
      for (final rule in st.rules)
        if (SocialApp.forPackage(rule.packageName) case final app?) (rule, app),
    ];

    return _Page(
      step: s.stepOf(2, _pages),
      title: s.obAppsTitle,
      desc: s.obAppsDesc,
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.25,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (final (rule, app) in items)
            Builder(builder: (context) {
              final on = rule.isEnabled;
              final isInstalled =
                  installed.isEmpty || app.packages.any(installed.containsKey);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  notifier.setRuleEnabled(rule.id, !on);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: on ? p.text : p.line,
                      width: on ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppLogo(app: app, size: 44),
                          const Spacer(),
                          _Check(on: on),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        app.name,
                        style: TextStyle(
                          color: p.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (!isInstalled)
                        Text(s.notInstalled,
                            style: TextStyle(color: p.text3, fontSize: 12.5)),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _modePage(BuildContext context) {
    final s = context.s;
    final p = context.palette;
    return _Page(
      step: s.stepOf(3, _pages),
      title: s.obModeTitle,
      desc: s.obModeDesc,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Choice(
            icon: CupertinoIcons.hand_raised_fill,
            iconColor: p.warning,
            title: s.modeWarnTitle,
            desc: s.modeWarnDesc,
            selected: _mode == _StopMode.checkIn,
            onTap: () => setState(() => _mode = _StopMode.checkIn),
          ),
          const SizedBox(height: 12),
          _Choice(
            icon: CupertinoIcons.lock_fill,
            iconColor: p.danger,
            title: s.modeBlockTitle,
            desc: s.modeBlockDesc,
            selected: _mode == _StopMode.block,
            onTap: () => setState(() => _mode = _StopMode.block),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _mode == _StopMode.checkIn
                ? _numberSection(
                    context,
                    label: s.checkInEveryField,
                    controller: _warnCtrl,
                    placeholder: '100',
                    error: _warnError ? s.invalidCheckIn : null,
                    onChanged: () => setState(() => _warnError = false),
                  )
                : _numberSection(
                    context,
                    label: s.blockAfterLabel,
                    controller: _blockCtrl,
                    placeholder: '300',
                    error: _blockError ? s.invalidNumber : null,
                    onChanged: () => setState(() => _blockError = false),
                    note: s.modeBlockNote(ref.watch(appStateProvider).warnEvery),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _numberSection(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required String? error,
    required VoidCallback onChanged,
    String? note,
  }) {
    final p = context.palette;
    return Padding(
      key: ValueKey(label),
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              label,
              style: TextStyle(color: p.text2, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          BigNumberField(
            controller: controller,
            autofocus: false,
            placeholder: placeholder,
            error: error,
            onChanged: (_) => onChanged(),
          ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
              child: Text(note, style: TextStyle(color: p.text2, fontSize: 13.5, height: 1.4)),
            ),
        ],
      ),
    );
  }
}

/// Scrollable page body: step label, big title, description, content.
class _Page extends StatelessWidget {
  final String step;
  final String title;
  final String desc;
  final Widget child;
  final bool padded;
  final Widget? leading;

  const _Page({
    required this.step,
    required this.title,
    required this.desc,
    required this.child,
    this.padded = true,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      padding: const EdgeInsets.only(top: 24, bottom: 24),
      physics: const BouncingScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[leading!, const SizedBox(height: 28)],
              Text(
                step.toUpperCase(),
                style: TextStyle(
                  color: p.text3,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              Text(title, style: AppTheme.display(size: 34, color: p.text)),
              const SizedBox(height: 10),
              Text(desc, style: TextStyle(color: p.text2, fontSize: 16, height: 1.4)),
              const SizedBox(height: 28),
            ],
          ),
        ),
        padded ? Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child) : child,
      ],
    );
  }
}

/// Selectable card: optional icon or text badge, title, optional description.
class _Choice extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String? badge;
  final String title;
  final String? desc;
  final bool selected;
  final VoidCallback onTap;

  const _Choice({
    this.icon,
    this.iconColor,
    this.badge,
    required this.title,
    this.desc,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? p.text : p.line, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            if (icon != null)
              IconTile(icon: icon!, color: iconColor ?? p.accent)
            else if (badge != null)
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: p.surface2,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Text(
                  badge!,
                  style: TextStyle(color: p.text, fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: p.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (desc != null) ...[
                    const SizedBox(height: 3),
                    Text(desc!, style: TextStyle(color: p.text2, fontSize: 14, height: 1.35)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _Check(on: selected),
          ],
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  final bool on;
  const _Check({required this.on});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? p.text : Colors.transparent,
        border: Border.all(color: on ? p.text : p.text3, width: 1.5),
      ),
      child: on ? Icon(CupertinoIcons.checkmark_alt, size: 16, color: p.bg) : null,
    );
  }
}
