import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:docflow_immigrati/core/services/ads_consent.dart';

/// Records every platform call in order; each step can be held open.
class FakeConsentPlatform implements ConsentPlatform {
  final List<String> calls = [];
  Completer<void> update = Completer<void>();
  Completer<void> form = Completer<void>();
  bool canRequest = true;
  bool privacyRequired = false;

  @override
  Future<void> requestConsentInfoUpdate() {
    calls.add('update');
    return update.future;
  }

  @override
  Future<void> loadAndShowConsentFormIfRequired() {
    calls.add('form');
    return form.future;
  }

  @override
  Future<bool> canRequestAds() async {
    calls.add('canRequestAds');
    return canRequest;
  }

  @override
  Future<bool> isPrivacyOptionsRequired() async => privacyRequired;

  @override
  Future<void> showPrivacyOptionsForm() async {
    calls.add('privacyForm');
  }

  @override
  Future<void> initializeMobileAds() async {
    calls.add('init');
  }
}

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late FakeConsentPlatform fake;

  setUp(() {
    fake = FakeConsentPlatform();
    AdsConsent.resetForTest(fake);
  });

  test('ads SDK starts only after consent update and form', () async {
    var adLoaded = false;
    AdsConsent.start(timeout: const Duration(seconds: 30));
    AdsConsent.whenReady.then((_) => adLoaded = true);

    await _settle();
    expect(fake.calls, ['update']);
    expect(adLoaded, isFalse);

    fake.update.complete();
    await _settle();
    expect(fake.calls, ['update', 'form']);
    expect(adLoaded, isFalse);

    fake.form.complete();
    await _settle();
    expect(fake.calls, ['update', 'form', 'canRequestAds', 'init']);
    expect(adLoaded, isTrue);
  });

  test('beforeInit and afterInit run around MobileAds init', () async {
    final order = <String>[];
    fake.update.complete();
    fake.form.complete();
    AdsConsent.start(
      beforeInit: () async => order.add('att'),
      afterInit: () async => order.add('config'),
    );
    await AdsConsent.whenReady;
    order.add('ad');
    expect(order, ['att', 'config', 'ad']);
    expect(fake.calls.last, 'init');
  });

  test('no ads when consent does not allow requesting them', () async {
    fake.canRequest = false;
    fake.update.complete();
    fake.form.complete();
    AdsConsent.start();
    await _settle();
    expect(AdsConsent.isReady, isFalse);
    expect(fake.calls, isNot(contains('init')));
  });

  test('offline: timeout uses cached consent instead of hanging', () async {
    // The update never answers; consent from a previous session is valid.
    AdsConsent.start(timeout: const Duration(milliseconds: 30));
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(AdsConsent.isReady, isTrue);
    expect(fake.calls, ['update', 'canRequestAds', 'init']);
  });

  test('offline without previous consent: still no ads', () async {
    fake.canRequest = false;
    AdsConsent.start(timeout: const Duration(milliseconds: 30));
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(AdsConsent.isReady, isFalse);
    expect(fake.calls, isNot(contains('init')));
  });

  test('privacy options entry follows the UMP status', () async {
    fake.privacyRequired = true;
    fake.update.complete();
    fake.form.complete();
    AdsConsent.start();
    await AdsConsent.whenReady;
    expect(AdsConsent.privacyOptionsRequired.value, isTrue);

    await AdsConsent.showPrivacyOptionsForm();
    expect(fake.calls, contains('privacyForm'));
    expect(fake.calls.where((c) => c == 'init').length, 1);
  });

  test('ready notifier flips only once ads may be requested', () async {
    expect(AdsConsent.ready.value, isFalse);
    AdsConsent.start(timeout: const Duration(seconds: 30));
    fake.update.complete();
    await _settle();
    expect(AdsConsent.ready.value, isFalse);
    fake.form.complete();
    await AdsConsent.whenReady;
    expect(AdsConsent.ready.value, isTrue);
  });
}
