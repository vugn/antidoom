import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'noop_monetization.dart';
import 'play_monetization.dart';

enum PurchaseState { idle, pending, error }

/// Ads and the one "Remove ads" purchase, behind one interface.
///
/// The foss build gets [NoopMonetization] (no ads, nothing to buy); the play
/// build gets [PlayMonetization]. Screens only talk to this class, so
/// contributors never need an AdMob or Play Console account.
abstract class Monetization extends ChangeNotifier {
  /// Picks the implementation from the Android flavor the app was built with.
  factory Monetization.forFlavor() =>
      appFlavor == 'play' ? PlayMonetization() : NoopMonetization();

  Monetization.base();

  /// True only in the Play build: it can show ads and sell "Remove ads".
  bool get hasStore;
  bool get adsRemoved;

  /// Localised price from Google Play, or null until it has loaded.
  String? get removeAdsPrice;
  PurchaseState get purchaseState;

  Future<void> init();
  Future<void> buyRemoveAds();
  Future<void> restorePurchases();

  /// A banner for the bottom of the dashboard, or nothing.
  Widget banner(BuildContext context);
}

/// main() overrides this with the flavor's implementation. The default is the
/// foss behaviour (no ads), so tests and previews never touch AdMob or billing.
final monetizationProvider = Provider<Monetization>((ref) => NoopMonetization());
