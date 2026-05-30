import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Adaptive banner needs the screen width (dp), only available once we
    // have a BuildContext. Load it exactly once.
    if (_requested || kIsWeb) return;
    _requested = true;
    final widthDp = MediaQuery.of(context).size.width.truncate();
    AdService().createAdaptiveBannerAd(
      widthDp: widthDp,
      onLoaded: () {
        if (mounted) setState(() => _isLoaded = true);
      },
    ).then((ad) {
      if (ad == null) return;
      if (!mounted) {
        ad.dispose();
        return;
      }
      _bannerAd = ad;
      ad.load();
    });
  }

  @override
  void dispose() {
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
