import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:docflow_immigrati/core/services/ad_retry.dart';
import 'package:docflow_immigrati/core/services/ad_service.dart';
import 'package:docflow_immigrati/core/services/ads_consent.dart';
import 'package:docflow_immigrati/core/widgets/banner_ad_widget.dart';

/// Consent platform that answers at once and allows ads.
class _InstantConsent implements ConsentPlatform {
  @override
  Future<void> requestConsentInfoUpdate() async {}
  @override
  Future<void> loadAndShowConsentFormIfRequired() async {}
  @override
  Future<bool> canRequestAds() async => true;
  @override
  Future<bool> isPrivacyOptionsRequired() async => false;
  @override
  Future<void> showPrivacyOptionsForm() async {}
  @override
  Future<void> initializeMobileAds() async {}
}

void main() {
  setUp(() {
    AdsConsent.resetForTest(_InstantConsent());
    BannerAdWidget.debugLoadAttempts = 0;
    BannerAdWidget.debugSkipPlatformLoad = true;
  });

  testWidgets('banner built before the gate loads once ads become ready',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BannerAdWidget())),
    );
    await tester.pump();
    // Built before consent: nothing requested.
    expect(BannerAdWidget.debugLoadAttempts, 0);

    AdsConsent.start(timeout: const Duration(seconds: 1));
    await tester.pump();
    await tester.pump();
    expect(AdsConsent.isReady, isTrue);
    // The same widget instance reacted to the notifier and requested an ad.
    expect(BannerAdWidget.debugLoadAttempts, 1);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('banner built after the gate loads immediately', (tester) async {
    AdsConsent.start(timeout: const Duration(seconds: 1));
    await tester.pump();
    await tester.pump();
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BannerAdWidget())),
    );
    expect(BannerAdWidget.debugLoadAttempts, 1);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('retry backoff: 30s, 60s, 2min, then every 4min',
      (tester) async {
    final retry = AdRetryBackoff();
    var calls = 0;
    final expected = [30, 60, 120, 240, 240, 240];
    for (final seconds in expected) {
      retry.schedule(() => calls++);
      final before = calls;
      await tester.pump(Duration(seconds: seconds - 1));
      expect(calls, before, reason: 'not before $seconds s');
      await tester.pump(const Duration(seconds: 1));
      expect(calls, before + 1, reason: 'fires at $seconds s');
    }
    retry.reset();
    expect(retry.nextDelay, const Duration(seconds: 30));
  });

  test('at least 60 s between two interstitials', () {
    final ads = AdService();
    final t0 = DateTime(2026, 1, 1, 12);
    ads.debugSetLastInterstitialAt(null);
    expect(ads.debugInterstitialAllowedAt(t0), isTrue);
    ads.debugSetLastInterstitialAt(t0);
    expect(ads.debugInterstitialAllowedAt(t0.add(const Duration(seconds: 59))),
        isFalse);
    expect(ads.debugInterstitialAllowedAt(t0.add(const Duration(seconds: 60))),
        isTrue);
    ads.debugSetLastInterstitialAt(null);
  });

  test('no interstitial while the PDF share sheet is open', () async {
    final ads = AdService();
    ads.debugSetLastInterstitialAt(null);
    bool? allowedDuringSheet;
    await ads.withShareSheet(() async {
      allowedDuringSheet = ads.canShowInterstitialNow;
    });
    expect(allowedDuringSheet, isFalse);
    expect(ads.debugShareSheetOpen, isFalse);
  });
}
