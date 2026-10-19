// Google UMP (User Messaging Platform) consent gate for AdMob.
//
// Order enforced here (required for full-value ads in the EEA/UK/CH):
//   1. ConsentInformation.requestConsentInfoUpdate(ConsentRequestParameters)
//   2. ConsentForm.loadAndShowConsentFormIfRequired
//   3. only then (or when canRequestAds() is already true from a previous
//      session) MobileAds.instance.initialize() and any ad load.
//
// Every ad load in the app waits on [AdsConsent.whenReady]. The gate never
// blocks the UI: it runs in the background after runApp, and a timeout lets
// returning users (whose consent is cached, so canRequestAds() is true) get
// ads even when the consent server cannot be reached (offline).
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// The platform calls the gate needs. Replaced by a fake in tests.
abstract class ConsentPlatform {
  /// Completes when the consent info update finished (success OR failure).
  Future<void> requestConsentInfoUpdate();

  /// Completes when the form was dismissed or was not required.
  Future<void> loadAndShowConsentFormIfRequired();

  Future<bool> canRequestAds();

  Future<bool> isPrivacyOptionsRequired();

  Future<void> showPrivacyOptionsForm();

  Future<void> initializeMobileAds();
}

class GoogleConsentPlatform implements ConsentPlatform {
  const GoogleConsentPlatform();

  @override
  Future<void> requestConsentInfoUpdate() {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        if (!done.isCompleted) done.complete();
      },
      (FormError error) {
        debugPrint('UMP consent info update failed: ${error.message}');
        if (!done.isCompleted) done.complete();
      },
    );
    return done.future;
  }

  @override
  Future<void> loadAndShowConsentFormIfRequired() {
    final done = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
      if (error != null) debugPrint('UMP consent form: ${error.message}');
      if (!done.isCompleted) done.complete();
    }).catchError((Object e) {
      debugPrint('UMP consent form error: $e');
      if (!done.isCompleted) done.complete();
    });
    return done.future;
  }

  @override
  Future<bool> canRequestAds() => ConsentInformation.instance.canRequestAds();

  @override
  Future<bool> isPrivacyOptionsRequired() async =>
      await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
      PrivacyOptionsRequirementStatus.required;

  @override
  Future<void> showPrivacyOptionsForm() {
    final done = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((FormError? error) {
      if (error != null) debugPrint('UMP privacy options: ${error.message}');
      if (!done.isCompleted) done.complete();
    }).catchError((Object e) {
      debugPrint('UMP privacy options error: $e');
      if (!done.isCompleted) done.complete();
    });
    return done.future;
  }

  @override
  Future<void> initializeMobileAds() => MobileAds.instance.initialize();
}

class AdsConsent {
  AdsConsent._();

  static ConsentPlatform platform = const GoogleConsentPlatform();

  static Completer<void> _ready = Completer<void>();
  static bool _started = false;
  static bool _initStarted = false;
  static Future<void> Function()? _beforeInit;
  static Future<void> Function()? _afterInit;

  /// Becomes true once [whenReady] completed. Widgets built before the gate
  /// was ready (e.g. banners on the first screen) listen to this to load.
  static final ValueNotifier<bool> ready = ValueNotifier<bool>(false);

  /// True when the settings screen must offer a "Privacy options" entry.
  static final ValueNotifier<bool> privacyOptionsRequired =
      ValueNotifier<bool>(false);

  /// Completes once consent was gathered (or was already valid) and the
  /// Mobile Ads SDK was initialised. Never completes while ads may not be
  /// requested, so nothing is loaded without consent.
  static Future<void> get whenReady => _ready.future;

  static bool get isReady => _ready.isCompleted;

  /// Runs the consent flow once. [beforeInit] runs right before
  /// MobileAds.initialize (e.g. the iOS ATT prompt), [afterInit] right
  /// after it (e.g. request configuration).
  static Future<void> start({
    Duration timeout = const Duration(seconds: 12),
    Future<void> Function()? beforeInit,
    Future<void> Function()? afterInit,
  }) {
    if (_started) return whenReady;
    _started = true;
    _beforeInit = beforeInit;
    _afterInit = afterInit;

    var gatherFinished = false;
    final timer = Timer(timeout, () async {
      if (gatherFinished || _initStarted) return;
      // Consent server slow/unreachable: if consent from a previous session
      // still allows ads, go ahead; otherwise keep waiting for the flow.
      if (await _safeCanRequestAds()) await _initAds();
    });

    () async {
      try {
        await platform.requestConsentInfoUpdate();
        await platform.loadAndShowConsentFormIfRequired();
      } catch (e) {
        debugPrint('UMP consent flow error: $e');
      }
      gatherFinished = true;
      timer.cancel();
      await _refreshPrivacyOptions();
      if (await _safeCanRequestAds()) await _initAds();
    }();

    return whenReady;
  }

  /// Opens the UMP privacy options form (from the settings menu).
  static Future<void> showPrivacyOptionsForm() async {
    try {
      await platform.showPrivacyOptionsForm();
    } catch (e) {
      debugPrint('UMP privacy options error: $e');
    }
    await _refreshPrivacyOptions();
    if (await _safeCanRequestAds()) await _initAds();
  }

  static Future<void> _refreshPrivacyOptions() async {
    try {
      privacyOptionsRequired.value = await platform.isPrivacyOptionsRequired();
    } catch (_) {}
  }

  static Future<bool> _safeCanRequestAds() async {
    try {
      return await platform.canRequestAds();
    } catch (_) {
      return false;
    }
  }

  static Future<void> _initAds() async {
    if (_initStarted) return;
    _initStarted = true;
    try {
      await _beforeInit?.call();
    } catch (e) {
      debugPrint('beforeInit error: $e');
    }
    try {
      await platform.initializeMobileAds().timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('MobileAds init timeout or error: $e - continuing anyway');
    }
    try {
      await _afterInit?.call();
    } catch (e) {
      debugPrint('afterInit error: $e');
    }
    if (!_ready.isCompleted) _ready.complete();
    ready.value = true;
  }

  @visibleForTesting
  static void resetForTest(ConsentPlatform fake) {
    platform = fake;
    _ready = Completer<void>();
    _started = false;
    _initStarted = false;
    _beforeInit = null;
    _afterInit = null;
    privacyOptionsRequired.value = false;
    ready.value = false;
  }
}
