import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Digimon the user saved with the heart, kept on the device.
class Favorites extends ChangeNotifier {
  static const String _key = 'favorite_ids';

  final List<int> _ids = []; // newest first
  SharedPreferences? _prefs;

  Favorites() {
    _load();
  }

  Future<void> _load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      for (final id in (_prefs!.getStringList(_key) ?? const []).map(int.tryParse).whereType<int>()) {
        if (!_ids.contains(id)) _ids.add(id);
      }
      notifyListeners();
    } catch (_) {
      // Storage unavailable: hearts still work for this session.
    }
  }

  /// Saved ids, most recently saved first.
  List<int> get ids => List.unmodifiable(_ids);

  bool contains(int id) => _ids.contains(id);

  void toggle(int id) {
    if (!_ids.remove(id)) _ids.insert(0, id);
    notifyListeners();
    _prefs?.setStringList(_key, _ids.map((id) => '$id').toList());
  }
}
