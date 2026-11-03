import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';

/// What people do in the app, for usage numbers: which screens they open,
/// how they find Digimon and what they keep. Nothing about who they are.
abstract class AppAnalytics {
  /// Reports screen views from route names (see nav.dart).
  List<NavigatorObserver> get observers;

  /// A card was drawn on Home: by spinning the dial or tapping a card.
  void cardDrawn(int digimonId, {required bool fromDial});

  void digimonOpened(int digimonId, String? name);

  void evolutionsOpened(int digimonId);

  /// A search the user settled on (not every keystroke).
  void searched(String query, int results);

  void levelFiltered(String? level);

  void favoriteToggled(int digimonId, {required bool added});
}

/// Used in tests and anywhere Firebase isn't set up.
class NoAnalytics implements AppAnalytics {
  const NoAnalytics();

  @override
  List<NavigatorObserver> get observers => const [];

  @override
  void cardDrawn(int digimonId, {required bool fromDial}) {}

  @override
  void digimonOpened(int digimonId, String? name) {}

  @override
  void evolutionsOpened(int digimonId) {}

  @override
  void searched(String query, int results) {}

  @override
  void levelFiltered(String? level) {}

  @override
  void favoriteToggled(int digimonId, {required bool added}) {}
}

class FirebaseAppAnalytics implements AppAnalytics {
  final FirebaseAnalytics _analytics;

  FirebaseAppAnalytics([FirebaseAnalytics? analytics]) : _analytics = analytics ?? FirebaseAnalytics.instance;

  @override
  late final List<NavigatorObserver> observers = [FirebaseAnalyticsObserver(analytics: _analytics)];

  // Analytics must never break the app: failures are dropped.
  void _log(String name, [Map<String, Object>? parameters]) => unawaited(_analytics.logEvent(name: name, parameters: parameters).catchError((_) {}));

  @override
  void cardDrawn(int digimonId, {required bool fromDial}) => _log('draw_card', {'digimon_id': digimonId, 'method': fromDial ? 'dial' : 'tap'});

  @override
  void digimonOpened(int digimonId, String? name) => unawaited(
    _analytics
        .logViewItem(
          items: [AnalyticsEventItem(itemId: '$digimonId', itemName: name, itemCategory: 'digimon')],
        )
        .catchError((_) {}),
  );

  @override
  void evolutionsOpened(int digimonId) => _log('open_evolutions', {'digimon_id': digimonId});

  @override
  void searched(String query, int results) => unawaited(_analytics.logSearch(searchTerm: query, parameters: {'results': results}).catchError((_) {}));

  @override
  void levelFiltered(String? level) => _log('filter_level', {'level': level ?? 'all'});

  @override
  void favoriteToggled(int digimonId, {required bool added}) => _log(added ? 'add_favorite' : 'remove_favorite', {'digimon_id': digimonId});
}
