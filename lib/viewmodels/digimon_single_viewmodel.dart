import 'package:flutter/foundation.dart';

import '../data/digimon_repository.dart';
import '../models/digimon.dart';
import '../models/digimon_details.dart';

/// Loads one Digimon's details for the details screen.
class DigimonSingleViewModel extends ChangeNotifier {
  final DigimonRepository _repository;
  final Digimon digimon;

  DigimonSingleViewModel(this._repository, this.digimon);

  DigimonDetails? _details;
  bool _loading = false;
  bool _failed = false;
  bool _disposed = false;

  DigimonDetails? get details => _details;

  bool get loading => _loading;

  bool get failed => _failed;

  Future<void> load() async {
    if (_loading || _details != null) return;
    _loading = true;
    _failed = false;
    _notify();

    try {
      _details = await _repository.getDetails(digimon.id!);
    } catch (_) {
      _failed = true;
    } finally {
      _loading = false;
      _notify();
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
