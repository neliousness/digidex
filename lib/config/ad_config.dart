import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Every AdMob id the Dart code uses lives here.
///
/// Release builds use the real DigiDexPlus ad units; debug and profile builds
/// use Google's public TEST ids, so testing never serves (or clicks) real ads,
/// which AdMob treats as invalid traffic. The AdMob app id lives in
/// `android/app/src/main/AndroidManifest.xml` (com.google.android.gms.ads.APPLICATION_ID)
/// and `ios/Runner/Info.plist` (GADApplicationIdentifier).
class AdConfig {
  // Real ad units (AdMob app "DigiDexPlus", ca-app-pub-8384949057978598~4382764333).
  static const String _androidBannerId = 'ca-app-pub-8384949057978598/9531149231';
  static const String _androidInterstitialId = 'ca-app-pub-8384949057978598/1381196478';

  // There's no iOS app in AdMob yet, so iOS uses test ids in every build.
  static const String _iosBannerId = 'ca-app-pub-3940256099942544/2435281174';
  static const String _iosInterstitialId = 'ca-app-pub-3940256099942544/4411468910';

  // Google's test ids.
  static const String _testAndroidBannerId = 'ca-app-pub-3940256099942544/9214589741';
  static const String _testAndroidInterstitialId = 'ca-app-pub-3940256099942544/1033173712';

  /// Hashed device ids (comma-separated) that get test ads from the real ad
  /// units, for checking a release build on your own phone without invalid
  /// traffic. Only set for such checks:
  /// `flutter build apk --release --dart-define=ADMOB_TEST_DEVICE_IDS=<id>`.
  /// The id is printed in logcat by the Ads SDK ("setTestDeviceIds(...)").
  static const String testDeviceIds = String.fromEnvironment('ADMOB_TEST_DEVICE_IDS');

  /// Build with `--dart-define=ADMOB_USE_TEST_UNITS=true` to use Google's test
  /// ad units in a release build: they always fill, so banners and the
  /// interstitial can be checked on a phone while the real units are new.
  static const bool forceTestUnits = bool.fromEnvironment('ADMOB_USE_TEST_UNITS');

  /// An interstitial shows at most once per this many details screens opened…
  static const int detailOpensPerInterstitial = 5;

  /// …and never sooner than this after the previous one.
  static const Duration minTimeBetweenInterstitials = Duration(seconds: 90);

  /// Ads only run on Android and iOS (not in tests, on the web or desktop).
  static bool get supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static String get bannerId {
    if (Platform.isIOS) return _iosBannerId;
    return kReleaseMode && !forceTestUnits ? _androidBannerId : _testAndroidBannerId;
  }

  static String get interstitialId {
    if (Platform.isIOS) return _iosInterstitialId;
    return kReleaseMode && !forceTestUnits ? _androidInterstitialId : _testAndroidInterstitialId;
  }
}
