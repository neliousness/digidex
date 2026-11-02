import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/digimon_repository.dart';
import '../models/digimon_details.dart';

/// The home screen's deck: an endless row of random Digimon, fanned as a
/// hand. Cards are addressed by position (negative to the left of where the
/// deal started) and fetched lazily as they come near the screen.
///
/// One slot of the fan is selected (the middle one until the user taps
/// another). Whichever card sits in that slot is the drawn card, shown big;
/// scrolling the hand moves new cards through the slot.
class HomeViewModel extends ChangeNotifier {
  /// Cards fetched ahead on each side of the centre, off screen.
  static const int lookAhead = 7;

  /// Slots either side of the centre that are tappable (the visible fan).
  static const int maxSlot = 3;

  /// Used until the API says how many Digimon there are.
  static const int fallbackTotal = 1488;

  final DigimonRepository _repository;
  final Random _random;

  HomeViewModel(this._repository, {Random? random}) : _random = random ?? Random();

  final Map<int, DigimonDetails?> _cards = {};
  final Set<int> _loading = {};
  final Set<int> _usedIds = {};
  int? _total;
  Future<void>? _totalFuture;
  int _center = 0;
  int _slot = 0;
  int _draws = 0;
  bool _disposed = false;

  int? get total => _total;

  /// The fan slot that's selected, -[maxSlot]..[maxSlot]; 0 is the middle.
  int get selectedSlot => _slot;

  /// Position of the card shown big: the one in the selected slot.
  int get drawnIndex => _center + _slot;

  DigimonDetails? get drawnCard => _cards[drawnIndex];

  /// Goes up whenever the user taps a card, so the screen replays the draw.
  int get draws => _draws;

  /// The card at [index], or null while it loads (asking starts the load).
  DigimonDetails? cardAt(int index) {
    if (!_cards.containsKey(index)) _ensure(index);
    return _cards[index];
  }

  /// Deals the first cards around the start.
  Future<void> deal() async {
    _ensureAround(0);
    await _waitForLoads();
  }

  /// The hand has been scrolled so that [center] sits in the middle slot.
  void scrollTo(int center) {
    if (center == _center) return;
    _center = center;
    _ensureAround(center);
    _notify();
  }

  /// The user tapped the card at [index], which sits in fan [slot]: it's drawn
  /// and that slot stays selected while scrolling.
  void select(int index, {required int slot}) {
    final clamped = slot.clamp(-maxSlot, maxSlot);
    if (index == drawnIndex && clamped == _slot) return;
    _slot = clamped;
    _center = index - clamped;
    _draws++;
    _ensureAround(_center);
    _notify();
  }

  void _ensureAround(int center) {
    for (var i = center - lookAhead; i <= center + lookAhead; i++) {
      if (!_cards.containsKey(i)) _ensure(i);
    }
  }

  Future<void> _waitForLoads() async {
    while (_loading.isNotEmpty && !_disposed) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  Future<void> _ensure(int index) async {
    if (_loading.contains(index) || _cards.containsKey(index)) return;
    _loading.add(index);
    _cards[index] = null;
    try {
      await (_totalFuture ??= _loadTotal());
      // A few ids may not exist; try another rather than leave a gap.
      for (var attempt = 0; attempt < 3 && !_disposed; attempt++) {
        try {
          _cards[index] = await _repository.getDetails(_nextId());
          return;
        } catch (_) {}
      }
    } finally {
      _loading.remove(index);
      _notify();
    }
  }

  Future<void> _loadTotal() async {
    try {
      _total = (await _repository.getPage(0)).total;
    } catch (_) {}
  }

  /// A random id, distinct from the ones dealt while there are enough to go round.
  int _nextId() {
    final total = _total ?? fallbackTotal;
    if (_usedIds.length >= total) _usedIds.clear();
    while (true) {
      final id = 1 + _random.nextInt(total);
      if (_usedIds.add(id)) return id;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
