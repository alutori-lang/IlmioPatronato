import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Premium PRO entitlement + the freemium gates.
///
/// Model: a SINGLE one-time non-consumable purchase ("premium_pro") that:
///   - removes ALL ads (banner / interstitial / rewarded video on open),
///   - makes the AI chat unlimited (non-premium = [freeAiMessagesPerDay]/day).
///
/// Calculators and document generators stay FREE for everyone (they earn ad
/// money via the rewarded video) — premium only removes the friction.
///
/// The store is the source of truth; we cache the flag in SharedPreferences so
/// it survives restarts and works offline. Singleton so [AdService] and the UI
/// share one instance.
class PremiumService extends ChangeNotifier {
  static final PremiumService _instance = PremiumService._();
  factory PremiumService() => _instance;
  PremiumService._();

  /// In-app product id — must match the product created in the stores.
  /// Android keeps `premium_pro` (already live on Play Console, untouched).
  /// iOS uses a distinct id: App Store Connect permanently reserves a product
  /// id once created, and `premium_pro` was burned on a first (wrong-type)
  /// draft — so iOS gets a fresh non-consumable id `premium_pro_lifetime`.
  static String get productId =>
      Platform.isIOS ? 'premium_pro_lifetime' : 'premium_pro';

  /// Free AI messages per day for non-premium users.
  static const int freeAiMessagesPerDay = 5;

  static const String _kPremium = 'is_premium_pro';
  static const String _kAiDate = 'ai_msg_date';
  static const String _kAiCount = 'ai_msg_count';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  List<ProductDetails> _products = [];
  ProductDetails? get product => _products.isNotEmpty ? _products.first : null;

  /// Localized store price (e.g. "3,99 €"), or null until products load.
  String? get priceLabel => product?.price;

  bool _storeAvailable = false;
  bool get storeAvailable => _storeAvailable;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_kPremium) ?? false;
    notifyListeners();

    _sub = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _sub?.cancel(),
      onError: (_) {},
    );

    _storeAvailable = await _iap.isAvailable();
    if (!_storeAvailable) return;
    try {
      final resp = await _iap.queryProductDetails({productId});
      _products = resp.productDetails;
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// Launch the store payment sheet for the premium product.
  Future<void> buy() async {
    final p = product;
    if (p == null) return;
    await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: p),
    );
  }

  /// Re-check past purchases (reinstall / new device). Required by store rules.
  Future<void> restore() async {
    await _iap.restorePurchases();
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final pd in purchases) {
      if (pd.productID == productId &&
          (pd.status == PurchaseStatus.purchased ||
              pd.status == PurchaseStatus.restored)) {
        await _grantPremium();
      }
      // Always finish the transaction or the store keeps re-delivering it.
      if (pd.pendingCompletePurchase) {
        await _iap.completePurchase(pd);
      }
    }
  }

  Future<void> _grantPremium() async {
    if (_isPremium) return;
    _isPremium = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPremium, true);
    notifyListeners();
  }

  // ── AI daily limit (non-premium) ──────────────────────────────────────────

  /// Free AI messages left today. Premium → effectively unlimited.
  Future<int> remainingAiMessages() async {
    if (_isPremium) return 1 << 30;
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final count =
        (prefs.getString(_kAiDate) == today) ? (prefs.getInt(_kAiCount) ?? 0) : 0;
    final left = freeAiMessagesPerDay - count;
    return left < 0 ? 0 : left;
  }

  Future<bool> canSendAiMessage() async =>
      _isPremium || (await remainingAiMessages()) > 0;

  /// Call AFTER a successful AI send to consume one free message.
  Future<void> registerAiMessage() async {
    if (_isPremium) return;
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final count =
        (prefs.getString(_kAiDate) == today) ? (prefs.getInt(_kAiCount) ?? 0) : 0;
    await prefs.setString(_kAiDate, today);
    await prefs.setInt(_kAiCount, count + 1);
  }

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }
}
