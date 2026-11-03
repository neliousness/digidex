import 'dart:async';

import 'package:digidexplus/ads/ad_service.dart';
import 'package:digidexplus/analytics/app_analytics.dart';
import 'package:digidexplus/art/art_service.dart';
import 'package:digidexplus/config/ad_config.dart';
import 'package:digidexplus/data/digimon_repository.dart';
import 'package:digidexplus/data/favorites.dart';
import 'package:digidexplus/sound/card_sounds.dart';
import 'package:digidexplus/theme/comic.dart';
import 'package:digidexplus/utils/rest_client.dart';
import 'package:digidexplus/viewmodels/browse_viewmodel.dart';
import 'package:digidexplus/viewmodels/home_viewmodel.dart';
import 'package:digidexplus/views/home_view.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final analytics = await _startFirebase();

  // The layouts are designed for a phone held upright.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Draw behind the system bars on every Android version, as Android 15+
  // enforces for apps targeting API 35+. Screens keep content clear of the
  // bars with SafeArea / MediaQuery padding.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // ink on the comic colours
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  final AdService adService;
  if (AdConfig.supported) {
    final mobileAds = MobileAdService();
    // Not awaited: the first frame shouldn't wait for the ads SDK.
    mobileAds.initialize();
    adService = mobileAds;
  } else {
    adService = const NoAdService();
  }

  runApp(
    DigiDexApp(
      repository: ApiDigimonRepository(RestClient(Dio())),
      adService: adService,
      artService: CutoutArtService(),
      sounds: AudioCardSounds()..warmUp(),
      analytics: analytics,
    ),
  );
}

/// Usage analytics and crash reports. Debug builds send nothing; without
/// Firebase (e.g. a misconfigured build) the app runs as before.
Future<AppAnalytics> _startFirebase() async {
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 5));
  } catch (_) {
    return const NoAnalytics();
  }
  final crashlytics = FirebaseCrashlytics.instance;
  unawaited(crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode));
  FlutterError.onError = crashlytics.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };
  return FirebaseAppAnalytics();
}

/// The app with its dependencies, so tests can pass fakes.
class DigiDexApp extends StatelessWidget {
  final DigimonRepository repository;
  final AdService adService;
  final ArtService artService;
  final CardSounds sounds;
  final AppAnalytics analytics;

  const DigiDexApp({
    super.key,
    required this.repository,
    this.adService = const NoAdService(),
    this.artService = const NoArtService(),
    this.sounds = const SilentCardSounds(),
    this.analytics = const NoAnalytics(),
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DigimonRepository>.value(value: repository),
        Provider<AdService>.value(value: adService),
        Provider<ArtService>.value(value: artService),
        Provider<CardSounds>.value(value: sounds),
        Provider<AppAnalytics>.value(value: analytics),
        ChangeNotifierProvider(create: (_) => Favorites()),
        ChangeNotifierProvider(create: (_) => HomeViewModel(repository)),
        ChangeNotifierProvider(create: (_) => BrowseViewModel(repository)),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DigiDex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: Comic.sans,
        colorScheme: ColorScheme.fromSeed(seedColor: Comic.yellow, primary: Comic.ink),
        textSelectionTheme: const TextSelectionThemeData(cursorColor: Comic.ink, selectionColor: Comic.yellow, selectionHandleColor: Comic.ink),
      ),
      navigatorObservers: context.read<AppAnalytics>().observers,
      initialRoute: HomeView.id,
      routes: {HomeView.id: (context) => const HomeView()},
    );
  }
}
