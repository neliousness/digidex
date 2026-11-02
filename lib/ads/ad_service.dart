import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';

/// Decides when an interstitial is due: after every [every] details screens,
/// and never within [minGap] of the previous one, so ads stay occasional.
class InterstitialPacer {
  final int every;
  final Duration minGap;
  final DateTime Function() _now;
  int _opensSinceAd = 0;
  DateTime? _lastShown;

  InterstitialPacer({this.every = AdConfig.detailOpensPerInterstitial, this.minGap = AdConfig.minTimeBetweenInterstitials, DateTime Function()? now})
      : assert(every > 0),
        _now = now ?? DateTime.now;

  /// Records a details screen being opened and says whether an ad is due now.
  bool recordOpen() {
    _opensSinceAd++;
    if (_opensSinceAd < every) return false;
    final last = _lastShown;
    if (last != null && _now().difference(last) < minGap) return false;
    return true;
  }

  /// An interstitial was actually shown: start counting again.
  void shown() {
    _opensSinceAd = 0;
    _lastShown = _now();
  }
}

abstract class AdService {
  /// Completes with true once ads may be requested: the SDK has started and
  /// the user's consent was gathered where the law requires it.
  Future<bool> get ready;

  void onDetailsOpened();
}

/// Used where ads can't run (tests, web, desktop).
class NoAdService implements AdService {
  const NoAdService();

  @override
  Future<bool> get ready => Future.value(false);

  @override
  void onDetailsOpened() {}
}

class MobileAdService implements AdService {
  final InterstitialPacer _pacer;
  InterstitialAd? _interstitial;
  bool _loadingInterstitial = false;

  final Completer<bool> _ready = Completer<bool>();

  MobileAdService({InterstitialPacer? pacer}) : _pacer = pacer ?? InterstitialPacer();

  /// Asks for consent where required (EEA/UK users see Google's consent form,
  /// configured under Privacy & messaging in AdMob), then starts the Mobile Ads
  /// SDK and preloads the first interstitial. Failures are swallowed: the app
  /// works the same without ads.
  Future<void> initialize() async {
    var canRequestAds = false;
    try {
      await _gatherConsent();
      canRequestAds = await ConsentInformation.instance.canRequestAds();
      if (canRequestAds) {
        if (AdConfig.testDeviceIds.isNotEmpty) {
          await MobileAds.instance.updateRequestConfiguration(RequestConfiguration(testDeviceIds: AdConfig.testDeviceIds.split(',')));
        }
        await MobileAds.instance.initialize();
        _loadInterstitial();
      }
    } catch (_) {
      canRequestAds = false;
    }
    if (!_ready.isCompleted) _ready.complete(canRequestAds);
  }

  Future<void> _gatherConsent() {
    final done = Completer<void>();
    void finish([Object? _]) {
      if (!done.isCompleted) done.complete();
    }

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => ConsentForm.loadAndShowConsentFormIfRequired(finish).catchError(finish),
      finish,
    );
    return done.future;
  }

  @override
  Future<bool> get ready => _ready.future;

  @override
  void onDetailsOpened() {
    if (!_ready.isCompleted) return;
    if (!_pacer.recordOpen()) return;
    final ad = _interstitial;
    if (ad == null) {
      // Due, but none loaded (no fill yet): keep it due and try on the next one.
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    _pacer.shown();
    ad.show().catchError((_) {
      ad.dispose();
      _loadInterstitial();
    });
  }

  void _loadInterstitial() {
    if (_interstitial != null || _loadingInterstitial) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _loadInterstitial();
            },
          );
          _interstitial = ad;
        },
        onAdFailedToLoad: (error) {
          _loadingInterstitial = false;
        },
      ),
    );
  }
}
