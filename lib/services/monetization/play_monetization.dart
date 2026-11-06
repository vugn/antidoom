import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../presentation/widgets/ad_banner.dart';
import '../native_bridge.dart';
import 'monetization.dart';

/// The Google Play build: one AdMob banner on the dashboard, and two one-time
/// purchases (non-consumable):
///   - `remove_ads`: removes the banner for good.
///   - `supporter`: supports the project; includes removing ads.
///
/// Ads never appear in the counter overlay or a check-in: those moments are
/// the product, and an ad there would work against it. Nothing that counts or
/// blocks is ever sold.
class PlayMonetization extends Monetization with WidgetsBindingObserver {
  PlayMonetization() : super.base();

  static const _prefsAdsRemoved = 'ads_removed';
  static const _prefsSupporter = 'supporter';

  /// Banner unit: `admobBannerId` in android/admob.properties (read through
  /// the native side), or `--dart-define=ADMOB_BANNER_ID=...` to override.
  /// Without either, Google's public test banner is used.
  static const _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const _definedBannerId = String.fromEnvironment('ADMOB_BANNER_ID');
  String _bannerUnitId = _testBannerId;

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  final Map<StoreProduct, ProductDetails> _products = {};
  bool _adsRemoved = false;
  bool _supporter = false;
  bool _canRequestAds = false;
  PurchaseState _state = PurchaseState.idle;
  StoreProduct? _active;

  /// True once Google Play itself reported a pending purchase (slow payment
  /// methods). Our own "pending" from [buy] is only a guess until then.
  bool _storePending = false;

  @override
  bool get hasStore => true;
  @override
  bool get adsRemoved => _adsRemoved || _supporter;
  @override
  bool get isSupporter => _supporter;
  @override
  String? priceOf(StoreProduct product) => _products[product]?.price;
  @override
  PurchaseState get purchaseState => _state;
  @override
  StoreProduct? get activeProduct => _active;

  @override
  Future<void> init() async {
    _bannerUnitId = _definedBannerId.isNotEmpty
        ? _definedBannerId
        : (await NativeBridge.getAdmobBannerId()) ?? _testBannerId;
    final prefs = await SharedPreferences.getInstance();
    _adsRemoved = prefs.getBool(_prefsAdsRemoved) ?? false;
    _supporter = prefs.getBool(_prefsSupporter) ?? false;
    notifyListeners();
    WidgetsBinding.instance.addObserver(this);

    try {
      _sub = _iap.purchaseStream.listen(
        _onPurchases,
        onError: (Object _) => _setState(PurchaseState.error),
      );
      if (await _iap.isAvailable()) {
        final res = await _iap.queryProductDetails({
          for (final p in StoreProduct.values) p.id,
        });
        for (final d in res.productDetails) {
          final p = StoreProduct.fromId(d.id);
          if (p != null) _products[p] = d;
        }
        notifyListeners();
        // Picks up purchases made on another device or before a reinstall.
        await _iap.restorePurchases();
      }
    } catch (e) {
      debugPrint('Billing unavailable: $e');
    }

    if (!adsRemoved) await _initAds();
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
      final product = StoreProduct.fromId(p.productID);
      if (product == null) {
        // Google Play reports a cancelled or failed purchase flow with an
        // empty product id, so it can't be matched to a product. Without
        // this the button stayed on "Waiting for Google Play" for good.
        if (p.status == PurchaseStatus.canceled) {
          _active = null;
          _storePending = false;
          _setState(PurchaseState.idle);
        } else if (p.status == PurchaseStatus.error) {
          _storePending = false;
          _setState(PurchaseState.error);
        }
        continue;
      }
      switch (p.status) {
        case PurchaseStatus.pending:
          _active = product;
          _storePending = true;
          _setState(PurchaseState.pending);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _grant(product);
          _storePending = false;
          if (_active == product) _active = null;
          _setState(PurchaseState.idle);
        case PurchaseStatus.error:
          _active = product;
          _storePending = false;
          _setState(PurchaseState.error);
        case PurchaseStatus.canceled:
          _storePending = false;
          if (_active == product) _active = null;
          _setState(PurchaseState.idle);
      }
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
    }
  }

  Future<void> _grant(StoreProduct product) async {
    final prefs = await SharedPreferences.getInstance();
    switch (product) {
      case StoreProduct.removeAds:
        if (_adsRemoved) return;
        _adsRemoved = true;
        await prefs.setBool(_prefsAdsRemoved, true);
      case StoreProduct.supporter:
        if (_supporter) return;
        _supporter = true;
        await prefs.setBool(_prefsSupporter, true);
    }
    notifyListeners();
  }

  /// Back from the Google Play sheet: if Play never reported anything (the
  /// sheet was dismissed in a way that sends no event), unlock the buttons.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_state != PurchaseState.pending || _storePending) return;
    Future.delayed(const Duration(seconds: 2), () {
      if (_state == PurchaseState.pending && !_storePending) {
        _active = null;
        _setState(PurchaseState.idle);
      }
    });
  }

  void _setState(PurchaseState s) {
    _state = s;
    notifyListeners();
  }

  @override
  Future<void> buy(StoreProduct product) async {
    _active = product;
    final details = _products[product];
    final owned = product == StoreProduct.supporter ? _supporter : adsRemoved;
    if (details == null || owned) {
      _setState(PurchaseState.error);
      return;
    }
    _setState(PurchaseState.pending);
    try {
      await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: details));
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
    if (adsRemoved || !_canRequestAds) return const SizedBox.shrink();
    return AdBanner(unitId: _bannerUnitId);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.dispose();
  }
}
