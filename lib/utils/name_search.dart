import '../models/digimon.dart';

/// Finds Digimon by name on the device.
///
/// The API's name filter only matches the start of a word in the base name
/// ("blue" doesn't find "Greymon (Blue)", "antibody" finds no X-Antibody
/// forms), so search runs locally over the full list instead: case,
/// punctuation and spacing are ignored, and a number finds that id.
class NameSearch {
  final List<Digimon> _all;
  final List<String> _words; // "greymon x antibody"
  final List<String> _squashed; // "greymonxantibody"

  NameSearch(List<Digimon> all)
      : _all = List.unmodifiable(all),
        _words = all.map((d) => normalize(d.name ?? '')).toList(),
        _squashed = all.map((d) => squash(d.name ?? '')).toList();

  int get length => _all.length;

  /// Lower case, letters and digits only, single spaces between words.
  static String normalize(String text) => text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

  static String squash(String text) => normalize(text).replaceAll(' ', '');

  /// Every Digimon matching [query], best matches first: the name starting
  /// with it, then a word starting with it, then anywhere. Ties keep API order.
  /// An empty query returns everything; "1", "#001" also find id 1. A query
  /// with no letters or digits ("%", "日本") matches nothing.
  List<Digimon> search(String query, {Set<int>? onlyIds}) {
    bool allowed(Digimon d) => onlyIds == null || onlyIds.contains(d.id);
    final q = normalize(query);
    if (query.trim().isEmpty) return [for (final d in _all) if (allowed(d)) d];
    if (q.isEmpty) return const [];

    final qSquashed = q.replaceAll(' ', '');
    final idQuery = RegExp(r'^#?\s*(\d+)$').firstMatch(query.trim());
    final id = idQuery == null ? null : int.tryParse(idQuery.group(1)!);

    final ranked = <(int rank, int order, Digimon d)>[];
    for (var i = 0; i < _all.length; i++) {
      final d = _all[i];
      if (!allowed(d)) continue;
      final words = _words[i];
      int? rank;
      if (id != null && d.id == id) {
        rank = 0;
      } else if (words.startsWith(q)) {
        rank = 1;
      } else if (words.contains(' $q')) {
        rank = 2;
      } else if (words.contains(q) || _squashed[i].contains(qSquashed)) {
        rank = 3;
      }
      if (rank != null) ranked.add((rank, i, d));
    }
    ranked.sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
    return [for (final r in ranked) r.$3];
  }
}
