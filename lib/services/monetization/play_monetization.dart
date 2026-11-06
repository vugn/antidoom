import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../presentation/widgets/ad_banner.dart';
import 'monetization.dart';

/// The Google Play build: one AdMob banner on the dashboard, removed for good
/// by a one-time "Remove ads" purchase (non-consumable `remove_ads`).
///
/// Ads never appear in the counter overlay or a check-in: those moments are
/// the product, and an ad there would work against it.
class PlayMonetization extends Monetization {
  PlayMonetization() : super.base();

  static const removeAdsId = 'remove_ads';
  static const _prefsKey = 'ads_removed';

  /// Real unit ID comes from `--dart-define=ADMOB_BANNER_ID=...` (CI secret).
  /// Without it, Google's public test banner is used, so dev builds never
  /// show live ads.
  static const bannerUnitId = String.fromEnvironment(
    'ADMOB_BANNER_ID',
    defaultValue: 'ca-app-pub-3940256099942544/6300978111',
  );

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  ProductDetails? _product;
  bool _adsRemoved = false;
  bool _canRequestAds = false;
  PurchaseState _state = PurchaseState.idle;

  @override
  bool get hasStore => true;
  @override
  bool get adsRemoved => _adsRemoved;
  @override
  String? get removeAdsPrice => _product?.price;
  @override
  PurchaseState get purchaseState => _state;

  @override
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _adsRemoved = prefs.getBool(_prefsKey) ?? false;
    notifyListeners();

    try {
      _sub = _iap.purchaseStream.listen(
        _onPurchases,
        onError: (Object _) => _setState(PurchaseState.error),
      );
      if (await _iap.isAvailable()) {
        final res = await _iap.queryProductDetails({removeAdsId});
        _product = res.productDetails.isEmpty ? null : res.productDetails.first;
        notifyListeners();
        // Picks up a purchase made on another device or before a reinstall.
        await _iap.restorePurchases();
      }
    } catch (e) {
      debugPrint('Billing unavailable: $e');
    }

    if (!_adsRemoved) await _initAds();
  }

  /// Asks for consent where the law requires it (EEA/UK), then starts AdMob.
  Future<void> _initAds() async {
    try {
      final done = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
          if (!done.isCompleted) done.complete();
        },
        (_) {
          if (!done.isCompleted) done.complete();
        },
      );
      await done.future;
      if (await ConsentInformation.instance.canRequestAds()) {
        await MobileAds.instance.initialize();
        _canRequestAds = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Ads unavailable: $e');
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != removeAdsId) continue;
      switch (p.status) {
        case PurchaseStatus.pending:
          _setState(PurchaseState.pending);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _markRemoved();
          _setState(PurchaseState.idle);
        case PurchaseStatus.error:
          _setState(PurchaseState.error);
        case PurchaseStatus.canceled:
          _setState(PurchaseState.idle);
      }
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
    }
  }

  Future<void> _markRemoved() async {
    if (_adsRemoved) return;
    _adsRemoved = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
    notifyListeners();
  }

  void _setState(PurchaseState s) {
    _state = s;
    notifyListeners();
  }

  @override
  Future<void> buyRemoveAds() async {
    final product = _product;
    if (product == null || _adsRemoved) {
      _setState(PurchaseState.error);
      return;
    }
    _setState(PurchaseState.pending);
    try {
      await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
    } catch (_) {
      _setState(PurchaseState.error);
    }
  }

  @override
  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (_) {
      _setState(PurchaseState.error);
    }
  }

  @override
  Widget banner(BuildContext context) {
    if (_adsRemoved || !_canRequestAds) return const SizedBox.shrink();
    return const AdBanner(unitId: bannerUnitId);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
