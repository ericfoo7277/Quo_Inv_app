import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Thin wrapper around the RevenueCat SDK.
///
/// Configure the API keys below from RevenueCat → Project Settings → API keys.
/// Use the **public** SDK keys (prefixed with `appl_` for iOS and `goog_`
/// for Android). Leave them empty in mock/dev mode — all calls will safely
/// no-op without crashing the app.
class RevenueCatService {
  RevenueCatService._();
  static final RevenueCatService instance = RevenueCatService._();

  // TODO(billing): Fill these in from the RevenueCat dashboard.
  static const String _iosApiKey = String.fromEnvironment('RC_IOS_KEY');
  static const String _androidApiKey = String.fromEnvironment('RC_ANDROID_KEY');

  /// Entitlement identifier configured in RevenueCat. Keep in sync with the
  /// entitlement attached to the monthly/yearly products.
  static const String proEntitlementId = 'QuoSwift Pro';

  bool _configured = false;
  bool get isConfigured => _configured;

  /// Stream of pro-entitlement state emitted whenever RevenueCat reports a
  /// `CustomerInfo` update (purchase, restore, expiration, etc.).
  final StreamController<bool> _proController =
      StreamController<bool>.broadcast();
  Stream<bool> get proStream => _proController.stream;

  String? _apiKeyForPlatform() {
    if (kIsWeb) return null;
    if (Platform.isIOS || Platform.isMacOS) {
      return _iosApiKey.isEmpty ? null : _iosApiKey;
    }
    if (Platform.isAndroid) {
      return _androidApiKey.isEmpty ? null : _androidApiKey;
    }
    return null;
  }

  /// Call once at app start (after Supabase init). [userId] should be the
  /// Supabase auth user id so RevenueCat ties purchases to the same identity
  /// across re-installs.
  Future<void> init({String? userId}) async {
    final key = _apiKeyForPlatform();
    if (key == null) {
      if (kDebugMode) {
        debugPrint('RevenueCat: skipping init — API key not configured.');
      }
      return;
    }
    try {
      await Purchases.setLogLevel(
        kDebugMode ? LogLevel.warn : LogLevel.error,
      );
      final config = PurchasesConfiguration(key);
      if (userId != null && userId.isNotEmpty) {
        config.appUserID = userId;
      }
      await Purchases.configure(config);
      _configured = true;
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfo);
    } catch (e, st) {
      if (kDebugMode) debugPrint('RevenueCat init failed: $e\n$st');
    }
  }

  void _onCustomerInfo(CustomerInfo info) {
    final active = info.entitlements.active.containsKey(proEntitlementId);
    if (!_proController.isClosed) _proController.add(active);
  }

  /// Re-identify the current user with RevenueCat after login.
  Future<void> identify(String userId) async {
    if (!_configured) return;
    try {
      await Purchases.logIn(userId);
    } catch (e) {
      if (kDebugMode) debugPrint('RevenueCat logIn failed: $e');
    }
  }

  /// Reset to an anonymous user (call on logout).
  Future<void> reset() async {
    if (!_configured) return;
    try {
      await Purchases.logOut();
    } catch (e) {
      if (kDebugMode) debugPrint('RevenueCat logOut failed: $e');
    }
  }

  /// Returns the current default offering, or null if none / not configured.
  Future<Offering?> getCurrentOffering() async {
    if (!_configured) return null;
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current;
    } catch (e) {
      if (kDebugMode) debugPrint('RevenueCat getOfferings failed: $e');
      return null;
    }
  }

  /// Purchases the given package. Returns true if the `pro` entitlement is
  /// active after purchase. Throws on user-cancel so the caller can ignore.
  Future<bool> purchasePackage(Package package) async {
    if (!_configured) return false;
    final result = await Purchases.purchase(
      PurchaseParams.package(package),
    );
    return result.customerInfo.entitlements.active
        .containsKey(proEntitlementId);
  }

  /// Restores prior purchases. Returns true if `pro` is now active.
  Future<bool> restorePurchases() async {
    if (!_configured) return false;
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.active.containsKey(proEntitlementId);
    } catch (e) {
      if (kDebugMode) debugPrint('RevenueCat restore failed: $e');
      return false;
    }
  }

  /// Quick check of current entitlement status.
  Future<bool> isPro() async {
    if (!_configured) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(proEntitlementId);
    } catch (e) {
      if (kDebugMode) debugPrint('RevenueCat getCustomerInfo failed: $e');
      return false;
    }
  }
}
