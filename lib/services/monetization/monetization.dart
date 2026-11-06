import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'noop_monetization.dart';
import 'play_monetization.dart';

enum PurchaseState { idle, pending, error }

/// One-time Google Play products (non-consumable). Ids must match Play Console.
enum StoreProduct {
  /// Removes the dashboard ad.
  removeAds('remove_ads'),

  /// Supports the project; includes everything [removeAds] does, plus a
  /// supporter mark in the app. Never unlocks counting features: those stay
  /// free for everyone (and the foss build has all of them).
  supporter('supporter');

  const StoreProduct(this.id);
  final String id;

  static StoreProduct? fromId(String id) {
    for (final p in values) {
      if (p.id == id) return p;
    }
    return null;
  }
}

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

  /// True only in the Play build: it can show ads and sell products.
  bool get hasStore;

  /// Bought "Remove ads" or "Supporter".
  bool get adsRemoved;

  /// Bought "Supporter".
  bool get isSupporter;

  /// Localised price from Google Play, or null until it has loaded.
  String? priceOf(StoreProduct product);

  PurchaseState get purchaseState;

  /// The product whose purchase is pending or just failed.
  StoreProduct? get activeProduct;

  Future<void> init();
  Future<void> buy(StoreProduct product);
  Future<void> restorePurchases();

  /// A banner for the bottom of the dashboard, or nothing.
  Widget banner(BuildContext context);
}

/// main() overrides this with the flavor's implementation. The default is the
/// foss behaviour (no ads), so tests and previews never touch AdMob or billing.
final monetizationProvider = Provider<Monetization>((ref) => NoopMonetization());
