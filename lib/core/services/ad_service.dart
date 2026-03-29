import 'dart:io';
import 'dart:ui';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  // ── Android Ad Unit IDs ──
  static const String _androidBannerId =
      'ca-app-pub-9396424020196768/7002867207';
  static const String _androidInterstitialId =
      'ca-app-pub-9396424020196768/3586366378';

  // ── iOS Ad Unit IDs (da aggiungere quando crei l'app iOS su AdMob) ──
  static const String _iosBannerId =
      'ca-app-pub-9396424020196768/7002867207'; // TODO: sostituire con iOS ID
  static const String _iosInterstitialId =
      'ca-app-pub-9396424020196768/3586366378'; // TODO: sostituire con iOS ID

  static String get bannerAdUnitId =>
      Platform.isAndroid ? _androidBannerId : _iosBannerId;

  static String get interstitialAdUnitId =>
      Platform.isAndroid ? _androidInterstitialId : _iosInterstitialId;

  InterstitialAd? _interstitialAd;
  int _navigationCount = 0;
  static const int _interstitialInterval = 3;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _loadInterstitialAd();
  }

  // ── Banner ──
  BannerAd createBannerAd({VoidCallback? onLoaded}) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => onLoaded?.call(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
  }

  // ── Interstitial (smart: ogni 3 navigazioni) ──
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Chiama questo metodo ad ogni navigazione verso un dettaglio.
  /// Mostra l'interstitial solo ogni [_interstitialInterval] navigazioni.
  void onNavigateToDetail() {
    _navigationCount++;
    if (_navigationCount >= _interstitialInterval) {
      _navigationCount = 0;
      showInterstitial();
    }
  }

  void showInterstitial() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
    }
  }
}
