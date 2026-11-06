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
  bool get isSupporter => false;
  @override
  String? priceOf(StoreProduct product) => null;
  @override
  PurchaseState get purchaseState => PurchaseState.idle;
  @override
  StoreProduct? get activeProduct => null;

  @override
  Future<void> init() async {}
  @override
  Future<void> buy(StoreProduct product) async {}
  @override
  Future<void> restorePurchases() async {}

  @override
  Widget banner(BuildContext context) => const SizedBox.shrink();
}
