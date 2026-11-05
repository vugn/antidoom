import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/social_apps.dart';

// ---------------------------------------------------------------------------
// Liquid glass (pinned, never inside scrolling content)
// ---------------------------------------------------------------------------

/// Round liquid-glass icon button for floating top bars.
class GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final double size;

  const GlassButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: SizedBox(
          width: size,
          height: size,
          child: LiquidGlassLens(
            style: LiquidGlassStyle(
              shape: LiquidGlassShape.roundedRectangle(cornerRadius: size / 2),
              color: (dark ? Colors.white : Colors.white)
                  .withValues(alpha: dark ? 0.08 : 0.55),
              refractionIndex: 1.05,
              refractionWidth: 14,
              blur: 3,
            ),
            child: Center(child: Icon(icon, size: 21, color: p.text)),
          ),
        ),
      ),
    );
  }
}

/// A pinned top bar that floats over the scrolling page (iOS 26 style):
/// content scrolls underneath, with a soft fade so text never collides.
class FloatingTopBar extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final List<Widget> actions;

  const FloatingTopBar({
    super.key,
    this.leading,
    this.title,
    this.actions = const [],
  });

  static double heightOf(BuildContext context) =>
      MediaQuery.paddingOf(context).top + 64;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final top = MediaQuery.paddingOf(context).top;
    // Frosted bar (iOS style): content scrolling underneath is blurred,
    // so titles never collide with it.
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: top + 64,
          padding: EdgeInsets.fromLTRB(16, top + 6, 16, 6),
          color: p.bg.withValues(alpha: 0.82),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(child: title ?? const SizedBox()),
              for (final a in actions) ...[const SizedBox(width: 8), a],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Surfaces
// ---------------------------------------------------------------------------

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? p.surface,
        borderRadius: BorderRadius.circular(24),
        border: dark ? Border.all(color: p.line, width: 0.5) : null,
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: child,
    );
  }
}

/// Small grey label above a panel.
class GroupLabel extends StatelessWidget {
  final String text;
  const GroupLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 10),
      child: Text(
        text,
        style: TextStyle(
          color: context.palette.text2,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A list of rows inside one panel, separated by hairlines.
class RowList extends StatelessWidget {
  final List<Widget> children;
  const RowList({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1) {
        items.add(Divider(height: 0.5, thickness: 0.5, indent: 68, color: p.line));
      }
    }
    return Panel(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(children: items),
      ),
    );
  }
}

/// One row: leading (icon), title + optional subtitle, trailing.
class ListRow extends StatefulWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool chevron;

  const ListRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.chevron = false,
  });

  @override
  State<ListRow> createState() => _ListRowState();
}

class _ListRowState extends State<ListRow> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final row = AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      color: _down ? p.surface2 : Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      constraints: const BoxConstraints(minHeight: 64),
      child: Row(
        children: [
          widget.leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    color: p.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle!,
                    style: TextStyle(color: p.text2, fontSize: 13.5, height: 1.3),
                  ),
                ],
              ],
            ),
          ),
          if (widget.trailing != null) ...[const SizedBox(width: 12), widget.trailing!],
          if (widget.chevron) ...[
            const SizedBox(width: 8),
            Icon(CupertinoIcons.chevron_forward, size: 16, color: p.text3),
          ],
        ],
      ),
    );

    if (widget.onTap == null) return row;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap!();
      },
      child: row,
    );
  }
}

/// Rounded-square icon tile used as a row leading.
class IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  const IconTile({super.key, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

/// Brand logo of a supported social app as a rounded tile.
class AppLogo extends StatelessWidget {
  final SocialApp app;
  final double size;
  final bool dimmed;

  const AppLogo({super.key, required this.app, this.size = 38, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final r = BorderRadius.circular(size * 0.26);
    final Widget tile = app.fullBleed
        ? ClipRRect(
            borderRadius: r,
            child: Image.asset(app.logo, width: size, height: size, fit: BoxFit.cover),
          )
        : Container(
            width: size,
            height: size,
            padding: EdgeInsets.all(size * 0.2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: r,
              border: dark ? null : Border.all(color: p.line),
            ),
            child: Image.asset(app.logo, fit: BoxFit.contain),
          );
    return Opacity(opacity: dimmed ? 0.35 : 1, child: tile);
  }
}

/// Bottom sheet with a big number field. Returns the number, or null.
Future<int?> showNumberSheet(
  BuildContext context, {
  required String title,
  required String hint,
  required String saveLabel,
  required String errorText,
  int? initial,
  int min = 10,
  int max = 5000,
  String placeholder = '300',
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _NumberSheet(
      title: title,
      hint: hint,
      saveLabel: saveLabel,
      errorText: errorText,
      initial: initial,
      min: min,
      max: max,
      placeholder: placeholder,
    ),
  );
}

class _NumberSheet extends StatefulWidget {
  final String title, hint, saveLabel, errorText, placeholder;
  final int? initial;
  final int min, max;
  const _NumberSheet({
    required this.title,
    required this.hint,
    required this.saveLabel,
    required this.errorText,
    required this.initial,
    required this.min,
    required this.max,
    required this.placeholder,
  });

  @override
  State<_NumberSheet> createState() => _NumberSheetState();
}

class _NumberSheetState extends State<_NumberSheet> {
  late final _c = TextEditingController(
    text: widget.initial != null && widget.initial! > 0 ? '${widget.initial}' : '',
  );
  bool _error = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _save() {
    final v = int.tryParse(_c.text);
    if (v == null || v < widget.min || v > widget.max) {
      setState(() => _error = true);
      HapticFeedback.heavyImpact();
      return;
    }
    Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: AppTheme.display(size: 26, color: p.text)),
              const SizedBox(height: 8),
              Text(widget.hint,
                  style: TextStyle(color: p.text2, fontSize: 15, height: 1.4)),
              const SizedBox(height: 20),
              BigNumberField(
                controller: _c,
                placeholder: widget.placeholder,
                error: _error ? widget.errorText : null,
                onChanged: (_) => setState(() => _error = false),
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 20),
              PrimaryButton(label: widget.saveLabel, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}

/// Large numeric input with a "swipes" suffix.
class BigNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String? error;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final String placeholder;

  const BigNumberField({
    super.key,
    required this.controller,
    this.error,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = true,
    this.placeholder = '300',
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: p.surface2,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: error != null ? p.danger : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: autofocus,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  cursorColor: p.accent,
                  style: AppTheme.display(size: 40, color: p.text),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: placeholder,
                    hintStyle: AppTheme.display(size: 40, color: p.text3),
                  ),
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                ),
              ),
              Text(
                Localizations.localeOf(context).languageCode == 'id' ? 'swipe' : 'swipes',
                style: TextStyle(color: p.text2, fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Text(error!, style: TextStyle(color: p.danger, fontSize: 13)),
          ),
      ],
    );
  }
}

class AccentSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const AccentSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CupertinoSwitch(
      value: value,
      activeTrackColor: context.palette.accent,
      onChanged: (v) {
        HapticFeedback.selectionClick();
        onChanged(v);
      },
    );
  }
}

/// High-contrast full-width button (black in light mode, white in dark).
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool enabled;
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: CupertinoButton(
        color: p.text,
        borderRadius: BorderRadius.circular(28),
        padding: EdgeInsets.zero,
        disabledColor: p.text.withValues(alpha: 0.15),
        onPressed: !enabled
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onPressed();
              },
        child: Text(
          label,
          style: TextStyle(
            color: p.bg,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progress ring
// ---------------------------------------------------------------------------

class ProgressRing extends StatelessWidget {
  final double value;
  final double size;
  final double stroke;
  final Color color;
  final Color track;
  final Widget child;

  const ProgressRing({
    super.key,
    required this.value,
    required this.color,
    required this.track,
    required this.child,
    this.size = 240,
    this.stroke = 18,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(v, color, track, stroke),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color track;
  final double stroke;
  _RingPainter(this.value, this.color, this.track, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(r, 0, math.pi * 2, false, trackPaint);
    if (value <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [color.withValues(alpha: 0.55), color],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawArc(r, -math.pi / 2, math.pi * 2 * value, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter o) =>
      o.value != value || o.color != color || o.track != track;
}

/// Big number helper.
Text bigNumber(BuildContext context, String text, {double size = 72, Color? color}) {
  return Text(
    text,
    style: AppTheme.display(size: size, color: color ?? context.palette.text),
  );
}
