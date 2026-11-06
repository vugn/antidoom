import 'package:flutter/widgets.dart';

import 'monetization.dart';

/// The foss build: no ads, no store, nothing to buy.
class NoopMonetization extends Monetization {
  NoopMonetization() : super.base();

  @override
  bool get hasStore => false;
  @override
  bool get adsRemoved => true;
  @override
  String? get removeAdsPrice => null;
  @override
  PurchaseState get purchaseState => PurchaseState.idle;

  @override
  Future<void> init() async {}
  @override
  Future<void> buyRemoveAds() async {}
  @override
  Future<void> restorePurchases() async {}

  @override
  Widget banner(BuildContext context) => const SizedBox.shrink();
}
