import 'dart:io';
import 'dart:ui';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'premium_service.dart';

class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  // ── Android Ad Unit IDs ──
  // Units on the Play-linked app "Bonus Italia: ISEE NASpI 730" (~2212115423).
  static const String _androidBannerId =
      'ca-app-pub-9396424020196768/7321232293';
  static const String _androidInterstitialId =
      'ca-app-pub-9396424020196768/6651513413';

  // ── iOS Ad Unit IDs ──
  // App ID iOS: ca-app-pub-9396424020196768~7863269060 (in Info.plist)
  static const String _iosBannerId =
      'ca-app-pub-9396424020196768/8918926323';
  static const String _iosInterstitialId =
      'ca-app-pub-9396424020196768/5185134834';

  // ── Rewarded Ad Unit IDs ── (both REAL now)
  // Android unit on app ~2212115423; iOS unit on app ~7863269060.
  static const String _androidRewardedId =
      'ca-app-pub-9396424020196768/3172019473'; // REAL
  static const String _iosRewardedId =
      'ca-app-pub-9396424020196768/9953050246'; // REAL

  static String get bannerAdUnitId =>
      Platform.isAndroid ? _androidBannerId : _iosBannerId;

  static String get interstitialAdUnitId =>
      Platform.isAndroid ? _androidInterstitialId : _iosInterstitialId;

  static String get rewardedAdUnitId =>
      Platform.isAndroid ? _androidRewardedId : _iosRewardedId;

  // ── App Open Ad Unit IDs ── DISABLED
  // App-open ads are intentionally OFF: no real AdMob units were created for
  // them, so no test IDs ship to production. To re-enable later, create one
  // "App Open" unit per platform in AdMob and paste the real IDs below.
  static const String _androidAppOpenId = '';
  static const String _iosAppOpenId = '';

  static String get appOpenAdUnitId =>
      Platform.isAndroid ? _androidAppOpenId : _iosAppOpenId;

  InterstitialAd? _interstitialAd;
  int _navigationCount = 0;
  static const int _interstitialInterval = 3;
  // Per-route counters: tap n°1 niente ad, tap n°2 ad, n°3 niente, n°4 ad...
  final Map<String, int> _everyOtherCounters = {};

  // True while ANY full-screen ad (interstitial / rewarded / app-open) is on
  // screen. App-open checks this so it never stacks on top of another ad
  // (and so closing an interstitial doesn't re-trigger app-open on resume).
  bool _isShowingFullScreenAd = false;

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
    _loadRewardedAd();
    // App-open intentionally DORMANT for this app (utility app with a
    // sensitive audience — an ad on every return hurts retention/ratings).
    // To re-enable: uncomment below AND restore the lifecycle hook in
    // app.dart's _MainShellState (WidgetsBindingObserver →
    // showAppOpenIfAvailable on resume).
    // _loadAppOpenAd();
  }

  // ── Banner ──
  /// Anchored ADAPTIVE banner: fills the device width with the height the
  /// AdMob auction prefers for that width → higher eCPM than the old fixed
  /// 320×50 `AdSize.banner`. Falls back to a standard banner if the adaptive
  /// size can't be computed (e.g. width unknown on web).
  Future<BannerAd?> createAdaptiveBannerAd({
    required int widthDp,
    VoidCallback? onLoaded,
  }) async {
    if (PremiumService().isPremium) return null; // premium = no banner
    final AdSize? size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(widthDp);
    if (size == null) return null;
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => onLoaded?.call(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
  }

  // Kept for any caller still on the fixed-size banner.
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
              _isShowingFullScreenAd = false;
              ad.dispose();
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              _isShowingFullScreenAd = false;
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
    if (PremiumService().isPremium) return;
    _navigationCount++;
    if (_navigationCount >= _interstitialInterval) {
      _navigationCount = 0;
      showInterstitial();
    }
  }

  void showInterstitial() {
    if (_interstitialAd != null) {
      _isShowingFullScreenAd = true;
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
    if (PremiumService().isPremium) {
      navigate();
      return;
    }
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
    if (PremiumService().isPremium) {
      navigate();
      return;
    }
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
        _isShowingFullScreenAd = false;
        a.dispose();
        _loadInterstitialAd();
        navigate();
      },
      onAdFailedToShowFullScreenContent: (a, error) {
        _isShowingFullScreenAd = false;
        a.dispose();
        _loadInterstitialAd();
        navigate();
      },
    );
    try {
      _isShowingFullScreenAd = true;
      await ad.show();
    } catch (_) {
      _isShowingFullScreenAd = false;
      _loadInterstitialAd();
      navigate();
    }
  }

  // ── Rewarded (highest eCPM: user opts in to watch for a benefit) ──
  RewardedAd? _rewardedAd;
  bool _rewardedLoading = false;

  void _loadRewardedAd() {
    if (_rewardedAd != null || _rewardedLoading) return;
    _rewardedLoading = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedLoading = false;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _rewardedLoading = false;
        },
      ),
    );
  }

  bool get isRewardedReady => _rewardedAd != null;

  /// Shows a rewarded ad and runs [onReward] only when the user actually
  /// EARNS the reward (watched enough). [onReward] is also called if the ad
  /// isn't ready / fails — we never block the user from their own document
  /// over an ad-fill miss; we just miss that one impression and preload the
  /// next. Returns once the flow is resolved.
  Future<void> showRewardedThen(VoidCallback onReward) async {
    if (PremiumService().isPremium) {
      onReward(); // premium = no video, run the action directly
      return;
    }
    final ad = _rewardedAd;
    if (ad == null) {
      // Not filled yet — don't punish the user. Grant + preload for next time.
      _loadRewardedAd();
      onReward();
      return;
    }
    _rewardedAd = null;
    bool rewarded = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        _isShowingFullScreenAd = false;
        a.dispose();
        _loadRewardedAd();
        if (rewarded) onReward();
      },
      onAdFailedToShowFullScreenContent: (a, error) {
        _isShowingFullScreenAd = false;
        a.dispose();
        _loadRewardedAd();
        onReward(); // show failed → don't block the user
      },
    );
    try {
      _isShowingFullScreenAd = true;
      await ad.show(
        onUserEarnedReward: (_, _) {
          rewarded = true;
        },
      );
    } catch (_) {
      _isShowingFullScreenAd = false;
      _loadRewardedAd();
      onReward();
    }
  }

  /// "Video gate": shows the rewarded video, then runs [onDone] when the ad
  /// closes REGARDLESS of whether the reward was earned — so the user is never
  /// hard-blocked from the screen if they close the video early. If no ad is
  /// ready it falls through immediately (and preloads for next time). Used to
  /// show a video when OPENING a simulator, before calculating.
  Future<void> showRewardedGate(VoidCallback onDone) async {
    if (PremiumService().isPremium) {
      onDone(); // premium = open the calculator with no video
      return;
    }
    final ad = _rewardedAd;
    if (ad == null) {
      _loadRewardedAd();
      onDone();
      return;
    }
    _rewardedAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        _isShowingFullScreenAd = false;
        a.dispose();
        _loadRewardedAd();
        onDone();
      },
      onAdFailedToShowFullScreenContent: (a, error) {
        _isShowingFullScreenAd = false;
        a.dispose();
        _loadRewardedAd();
        onDone();
      },
    );
    try {
      _isShowingFullScreenAd = true;
      await ad.show(onUserEarnedReward: (_, _) {});
    } catch (_) {
      _isShowingFullScreenAd = false;
      _loadRewardedAd();
      onDone();
    }
  }

  // ── App Open (shows on return-to-foreground: 1 impression per session) ──
  AppOpenAd? _appOpenAd;
  DateTime? _appOpenLoadedAt;
  bool _appOpenLoading = false;
  // App-open creatives expire ~4h after load; don't show a stale one.
  static const Duration _appOpenMaxCacheAge = Duration(hours: 4);

  void _loadAppOpenAd() {
    if (appOpenAdUnitId.isEmpty) return; // app-open ads disabled
    if (_appOpenAd != null || _appOpenLoading) return;
    _appOpenLoading = true;
    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenLoadedAt = DateTime.now();
          _appOpenLoading = false;
        },
        onAdFailedToLoad: (error) {
          _appOpenAd = null;
          _appOpenLoading = false;
        },
      ),
    );
  }

  bool get _isAppOpenAvailable {
    if (_appOpenAd == null || _appOpenLoadedAt == null) return false;
    return DateTime.now().difference(_appOpenLoadedAt!) < _appOpenMaxCacheAge;
  }

  /// Call when the app returns to the foreground (warm start). Shows the
  /// app-open ad if one is ready and no other full-screen ad is up, then
  /// preloads the next. Never shown on the very first cold launch / onboarding
  /// because the lifecycle hook only fires this on resume-from-background.
  void showAppOpenIfAvailable() {
    if (appOpenAdUnitId.isEmpty) return; // app-open ads disabled
    if (_isShowingFullScreenAd) return; // don't stack on interstitial/rewarded
    if (!_isAppOpenAvailable) {
      _loadAppOpenAd(); // not ready → fetch for next time
      return;
    }
    final ad = _appOpenAd!;
    _appOpenAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (a) => _isShowingFullScreenAd = true,
      onAdDismissedFullScreenContent: (a) {
        _isShowingFullScreenAd = false;
        a.dispose();
        _loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (a, error) {
        _isShowingFullScreenAd = false;
        a.dispose();
        _loadAppOpenAd();
      },
    );
    ad.show();
  }
}
