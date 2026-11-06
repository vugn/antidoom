import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/localization/strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../services/monetization/monetization.dart';
import 'brand.dart';

/// Once in a while (Google Play build only) says thank you with confetti and
/// offers "Support AntiDoom" or "Remove ads". Never required: closing it just
/// goes back to the app, and nothing that counts or blocks is ever behind it.
///
/// Shown on the first time the dashboard opens, then on every [_every]th
/// app open after that (10th, 20th, ...), and never again once the user is a
/// supporter.
class ThankYouGate extends ConsumerStatefulWidget {
  const ThankYouGate({super.key});

  static const _every = 10;
  static const _kOpens = 'thanks_opens';

  /// Counted once per app launch.
  static bool _checked = false;

  @override
  ConsumerState<ThankYouGate> createState() => _ThankYouGateState();
}

class _ThankYouGateState extends ConsumerState<ThankYouGate> {
  @override
  void initState() {
    super.initState();
    if (ThankYouGate._checked) return;
    ThankYouGate._checked = true;
    // Wait for the splash eyes to finish and give billing time to load
    // prices and restore purchases, so the dialog never lands on the splash.
    Future.delayed(const Duration(milliseconds: 3000), _maybeShow);
  }

  Future<void> _maybeShow() async {
    final m = ref.read(monetizationProvider);
    if (!mounted || !m.hasStore) return;

    final prefs = await SharedPreferences.getInstance();
    final opens = (prefs.getInt(ThankYouGate._kOpens) ?? 0) + 1;
    await prefs.setInt(ThankYouGate._kOpens, opens);
    if (m.isSupporter) return;
    if (opens != 1 && opens % ThankYouGate._every != 0) return;

    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    if (mounted) await ThankYouSheet.show(context, m);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class ThankYouSheet extends StatefulWidget {
  const ThankYouSheet({super.key, required this.monetization});

  final Monetization monetization;

  static Future<void> show(BuildContext context, Monetization m) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, _, _) => ThankYouSheet(monetization: m),
      transitionBuilder: (_, anim, _, child) {
        final c = CurvedAnimation(parent: anim, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: Tween(begin: 0.88, end: 1.0).animate(c), child: child),
        );
      },
    );
  }

  @override
  State<ThankYouSheet> createState() => _ThankYouSheetState();
}

class _ThankYouSheetState extends State<ThankYouSheet> with TickerProviderStateMixin {
  late final AnimationController _confetti =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3400));
  late final AnimationController _bob =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  late final bool _wasSupporter = widget.monetization.isSupporter;
  late final bool _hadNoAds = widget.monetization.adsRemoved;
  int _burst = 0;
  bool _thanked = false;

  Monetization get m => widget.monetization;

  @override
  void initState() {
    super.initState();
    m.addListener(_onStore);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!MediaQuery.of(context).disableAnimations) {
        _confetti.forward();
        _bob.repeat(reverse: true);
      }
    });
  }

  /// A purchase went through while the sheet is open: say thanks again.
  void _onStore() {
    final bought = (m.isSupporter && !_wasSupporter) || (m.adsRemoved && !_hadNoAds);
    if (bought && !_thanked && mounted) {
      setState(() {
        _thanked = true;
        _burst++;
      });
      if (!MediaQuery.of(context).disableAnimations) _confetti.forward(from: 0);
    } else if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    m.removeListener(_onStore);
    _confetti.dispose();
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final p = context.palette;
    final pending = m.purchaseState == PurchaseState.pending;

    String label(StoreProduct product, String idle) {
      if (m.activeProduct == product) {
        if (pending) return s.purchasePending;
        if (m.purchaseState == PurchaseState.error) return s.purchaseFailed;
      }
      return idle;
    }

    final card = Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(CupertinoIcons.xmark, size: 20, color: p.text2),
              ),
            ),
            AnimatedBuilder(
              animation: _bob,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, -6 * Curves.easeInOut.transform(_bob.value)),
                child: child,
              ),
              child: const Center(child: BrandSymbol(size: 84, icon: true)),
            ),
            const SizedBox(height: 18),
            Text(
              _thanked ? s.thanksDoneTitle : s.thanksTitle,
              textAlign: TextAlign.center,
              style: AppTheme.display(size: 26, color: p.text),
            ),
            const SizedBox(height: 10),
            Text(
              _thanked ? s.thanksDoneBody : s.thanksBody,
              textAlign: TextAlign.center,
              style: TextStyle(color: p.text2, fontSize: 15, height: 1.45),
            ),
            const SizedBox(height: 22),
            if (_thanked)
              _button(p.text, p.bg, s.thanksDoneClose, null, () => Navigator.of(context).pop())
            else ...[
              if (!m.isSupporter)
                _button(
                  p.accent,
                  Colors.white,
                  label(StoreProduct.supporter, s.thanksSupport(m.priceOf(StoreProduct.supporter))),
                  CupertinoIcons.heart_fill,
                  pending ? null : () => m.buy(StoreProduct.supporter),
                ),
              if (!m.adsRemoved) ...[
                const SizedBox(height: 10),
                _button(
                  p.surface2,
                  p.text,
                  label(StoreProduct.removeAds, s.thanksRemoveAds(m.priceOf(StoreProduct.removeAds))),
                  CupertinoIcons.nosign,
                  pending ? null : () => m.buy(StoreProduct.removeAds),
                ),
              ],
              const SizedBox(height: 4),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(s.thanksLater,
                    style: TextStyle(color: p.text2, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              Text(
                s.thanksFreeNote,
                textAlign: TextAlign.center,
                style: TextStyle(color: p.text3, fontSize: 12.5, height: 1.4),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );

    return Stack(
      children: [
        Center(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(child: card),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _confetti,
              builder: (_, _) => CustomPaint(
                painter: _ConfettiPainter(_confetti.value, seed: 7 + _burst),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _button(Color bg, Color fg, String text, IconData? icon, VoidCallback? onTap) {
    return CupertinoButton(
      color: bg,
      disabledColor: bg.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 8)],
          Flexible(
            child: Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// Two party-popper bursts from the lower corners. Pure function of [t]
/// (0..1) so it's cheap and needs no per-frame state.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, {required this.seed});

  final double t;
  final int seed;

  static const _colors = [
    Color(0xFF12B76A),
    Color(0xFF32D583),
    Color(0xFFFFC247),
    Color(0xFFFF6B5B),
    Color(0xFF4DA3FF),
    Color(0xFFFF7AB6),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final rnd = math.Random(seed);
    final secs = t * 3.4;
    const gravity = 1500.0;
    final paint = Paint();
    for (var i = 0; i < 110; i++) {
      final left = i.isEven;
      final delay = rnd.nextDouble() * 0.25;
      final speed = 900 + rnd.nextDouble() * 900;
      final angle = 0.25 + rnd.nextDouble() * 0.55; // radians off straight up, toward the middle
      final vx = (left ? 1 : -1) * math.sin(angle) * speed;
      final vy = -math.cos(angle) * speed;
      final w = 7 + rnd.nextDouble() * 7;
      final h = w * (0.4 + rnd.nextDouble() * 0.5);
      final spin = (rnd.nextDouble() - 0.5) * 14;
      final sway = rnd.nextDouble() * 6;
      final color = _colors[rnd.nextInt(_colors.length)];
      final round = rnd.nextDouble() < 0.3;

      final tt = secs - delay;
      if (tt <= 0) continue;
      // Air drag: horizontal speed fades, the fall is capped.
      final drag = math.exp(-1.6 * tt);
      final x0 = left ? -10.0 : size.width + 10;
      final y0 = size.height * 0.78;
      final x = x0 + vx * (1 - drag) / 1.6 + math.sin(tt * 5 + sway) * 14;
      final y = y0 + vy * (1 - drag) / 1.6 + 0.5 * gravity * tt * tt * 0.35;
      final fade = (1 - ((secs - 2.4) / 1.0)).clamp(0.0, 1.0);
      if (fade <= 0 || y > size.height + 20) continue;

      paint.color = color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(spin * tt);
      // Fake 3D flip: squash on one axis over time.
      canvas.scale(1, math.cos(tt * (6 + sway)).abs().clamp(0.15, 1.0));
      if (round) {
        canvas.drawCircle(Offset.zero, w * 0.38, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: w, height: h), const Radius.circular(1.5)),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t || old.seed != seed;
}
