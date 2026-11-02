import 'package:flutter/foundation.dart';

import '../data/digimon_repository.dart';
import '../models/digimon.dart';
import '../utils/name_search.dart';

/// Browse and search. The full list is fetched once and searched on the
/// device, so results update as you type with no network round trip; a level
/// filter fetches that level's ids once.
class BrowseViewModel extends ChangeNotifier {
  final DigimonRepository _repository;

  BrowseViewModel(this._repository);

  NameSearch? _search;
  bool _loading = false;
  bool _failed = false;
  String _query = '';
  String? _level;
  Set<int>? _levelIds;
  bool _levelLoading = false;
  bool _levelFailed = false;
  int _levelRequest = 0;
  List<Digimon> _results = const [];
  bool _disposed = false;

  String get query => _query;

  String? get level => _level;

  /// Matches for the current query and level, best first.
  List<Digimon> get results => _results;

  /// How many Digimon there are in total, once the list is in.
  int? get total => _search?.length;

  /// The list (or a level) is loading for the first time.
  bool get loading => _loading || _levelLoading;

  /// The list or the level couldn't be fetched; [retry] tries again.
  bool get failed => _failed || _levelFailed;

  bool get filtered => _query.trim().isNotEmpty || _level != null;

  /// Everything is in, and the current search matched nothing.
  bool get noResults => _search != null && !loading && !failed && _results.isEmpty;

  /// Fetches the full list, once.
  Future<void> load() async {
    if (_search != null || _loading) return;
    _loading = true;
    _failed = false;
    _notify();
    try {
      _search = NameSearch(await _repository.getAll());
    } catch (_) {
      _failed = true;
    } finally {
      _loading = false;
      _recompute();
    }
  }

  void setQuery(String query) {
    if (query == _query) return;
    _query = query;
    _recompute();
  }

  /// Filters by [level] ("Child"), or clears the filter with null.
  Future<void> setLevel(String? level) async {
    if (level == _level && !_levelFailed) return;
    final request = ++_levelRequest;
    _level = level;
    _levelIds = null;
    _levelFailed = false;
    if (level == null) {
      _levelLoading = false;
      _recompute();
      return;
    }
    _levelLoading = true;
    _recompute();
    try {
      final ids = await _repository.getIdsAtLevel(level);
      if (request != _levelRequest) return; // a newer chip was tapped
      _levelIds = ids;
    } catch (_) {
      if (request != _levelRequest) return;
      _levelFailed = true;
    }
    _levelLoading = false;
    _recompute();
  }

  Future<void> retry() async {
    if (_search == null) await load();
    if (_levelFailed) await setLevel(_level);
  }

  void _recompute() {
    final search = _search;
    if (search == null || (_level != null && _levelIds == null)) {
      _results = const [];
    } else {
      _results = search.search(_query, onlyIds: _level == null ? null : _levelIds);
    }
    _notify();
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
