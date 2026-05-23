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

  // ── iOS Ad Unit IDs ──
  // App ID iOS: ca-app-pub-9396424020196768~7863269060 (in Info.plist)
  static const String _iosBannerId =
      'ca-app-pub-9396424020196768/8918926323';
  static const String _iosInterstitialId =
      'ca-app-pub-9396424020196768/5185134834';

  static String get bannerAdUnitId =>
      Platform.isAndroid ? _androidBannerId : _iosBannerId;

  static String get interstitialAdUnitId =>
      Platform.isAndroid ? _androidInterstitialId : _iosInterstitialId;

  InterstitialAd? _interstitialAd;
  int _navigationCount = 0;
  static const int _interstitialInterval = 3;
  // Per-route counters: tap n°1 niente ad, tap n°2 ad, n°3 niente, n°4 ad...
  final Map<String, int> _everyOtherCounters = {};

  Future<void> initialize() async {
    // No App Tracking Transparency: the app declares "no tracking" in the
    // App Privacy section on App Store Connect, so the ATT prompt is not
    // required and was removed entirely (Apple flagged a previous build
    // for declaring tracking + missing the prompt — guideline 2.1).
    // AdMob on iOS 14.5+ automatically falls back to non-personalized
    // ads when ATT has not been granted, which matches the privacy
    // declaration.
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

  /// Mostra l'ad ogni 2° tap su una stessa "chiave" (1° volta no, 2° sì,
  /// 3° no, 4° sì...). La chiave separa i contatori per tipo di servizio
  /// (es. 'bonus', 'guida_documenti'). Per AdMob policy: la 1° volta passa
  /// libero così non triggera interstitial all'inizio della sessione.
  Future<void> showAdEveryOther({
    required String key,
    required VoidCallback navigate,
  }) async {
    final count = (_everyOtherCounters[key] ?? 0) + 1;
    _everyOtherCounters[key] = count;
    if (count.isEven) {
      await showAdThenNavigate(navigate);
    } else {
      navigate();
    }
  }

  /// Mostra l'interstitial e SOLO quando viene chiuso esegue [navigate].
  /// Se l'ad non è caricato (o fallisce) [navigate] parte subito.
  /// Usato per: tap su un bonus → pubblicità → dettaglio bonus.
  Future<void> showAdThenNavigate(VoidCallback navigate) async {
    final ad = _interstitialAd;
    if (ad == null) {
      // Ad non pronto: navighi subito e provo a precaricarlo per la prossima volta.
      _loadInterstitialAd();
      navigate();
      return;
    }
    _interstitialAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadInterstitialAd();
        navigate();
      },
      onAdFailedToShowFullScreenContent: (a, error) {
        a.dispose();
        _loadInterstitialAd();
        navigate();
      },
    );
    try {
      await ad.show();
    } catch (_) {
      _loadInterstitialAd();
      navigate();
    }
  }
}
