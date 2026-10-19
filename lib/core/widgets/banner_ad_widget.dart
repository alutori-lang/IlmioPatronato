import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_retry.dart';
import '../services/ad_service.dart';
import '../services/ads_consent.dart';

/// Anchored adaptive banner.
///
/// Requests nothing before the consent gate ([AdsConsent]) is ready. A banner
/// built earlier (e.g. on the first screen) listens to [AdsConsent.ready] and
/// loads as soon as ads may be requested, instead of staying empty for the
/// whole session. A failed load retries after 30 s, 60 s, 2 min, then every
/// 4 min.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  /// Counts load attempts (tests only).
  @visibleForTesting
  static int debugLoadAttempts = 0;

  /// When true, attempts are counted but no platform ad is created (tests).
  @visibleForTesting
  static bool debugSkipPlatformLoad = false;

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _loading = false;
  int? _widthDp;
  final AdRetryBackoff _retry = AdRetryBackoff();

  @override
  void initState() {
    super.initState();
    AdsConsent.ready.addListener(_onAdsReady);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Adaptive banner needs the screen width (dp), only available once we
    // have a BuildContext.
    _widthDp = MediaQuery.of(context).size.width.truncate();
    _tryLoad();
  }

  void _onAdsReady() {
    if (!mounted) return;
    setState(() {});
    _tryLoad();
  }

  void _tryLoad() {
    if (kIsWeb || !mounted) return;
    if (_loading || _isLoaded || _bannerAd != null) return;
    if (!AdsConsent.isReady) return; // _onAdsReady calls us again later
    final widthDp = _widthDp;
    if (widthDp == null) return;
    BannerAdWidget.debugLoadAttempts++;
    if (BannerAdWidget.debugSkipPlatformLoad) return;
    _loading = true;
    AdService().createAdaptiveBannerAd(
      widthDp: widthDp,
      onLoaded: () {
        _retry.reset();
        if (mounted) setState(() => _isLoaded = true);
      },
      onFailed: _onFailed,
    ).then((ad) {
      if (ad == null) {
        _loading = false;
        return;
      }
      if (!mounted) {
        ad.dispose();
        return;
      }
      _bannerAd = ad;
      _loading = false;
      ad.load();
    }, onError: (_) {
      _loading = false;
      _onFailed();
    });
  }

  void _onFailed() {
    // The ad itself is disposed by the listener.
    _bannerAd = null;
    _loading = false;
    if (!mounted) return;
    setState(() => _isLoaded = false);
    _retry.schedule(_tryLoad);
  }

  @override
  void dispose() {
    AdsConsent.ready.removeListener(_onAdsReady);
    _retry.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  // TEMP_SCREENSHOTS: hide ads when capturing App Store screenshots
  // (--dart-define=SCREENSHOT_MODE=true). Real builds keep ads.
  static const bool _screenshotMode =
      bool.fromEnvironment('SCREENSHOT_MODE', defaultValue: false);

  @override
  Widget build(BuildContext context) {
    if (_screenshotMode) return const SizedBox.shrink();
    if (kIsWeb || !_isLoaded || _bannerAd == null) return const SizedBox.shrink();
    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
