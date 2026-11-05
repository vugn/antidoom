import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The AntiDoom "Look Up" logo. Light backgrounds use the line version (ink
/// rings, the background shows through as the white of the eye); dark
/// backgrounds use solid white eyes. Source files: brand/svg/.
class BrandWordmark extends StatelessWidget {
  final double height;

  const BrandWordmark({super.key, this.height = 24});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'AntiDoom',
      child: SvgPicture.asset(
        dark ? 'assets/brand/antidoom-wordmark-white.svg' : 'assets/brand/antidoom-wordmark.svg',
        height: height,
        excludeFromSemantics: true,
      ),
    );
  }
}

/// Just the eyes. [icon] draws the full-colour app icon (green tile).
class BrandSymbol extends StatelessWidget {
  final double size;
  final bool icon;

  const BrandSymbol({super.key, this.size = 48, this.icon = false});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final asset = icon
        ? 'assets/brand/antidoom-icon.svg'
        : dark
            ? 'assets/brand/antidoom-symbol-white.svg'
            : 'assets/brand/antidoom-symbol.svg';
    return SvgPicture.asset(asset, width: size, height: size, semanticsLabel: 'AntiDoom');
  }
}
