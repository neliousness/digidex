import '../models/content.dart';
import '../models/digimon.dart';
import '../models/digimon_details.dart';
import '../models/digimon_query.dart';
import '../models/lookup.dart';
import '../utils/rest_client.dart';

/// One page of the Digimon list.
class DigimonPage {
  final List<Digimon> digimon;
  final bool hasNextPage;

  /// How many Digimon match the query across all pages, if the API says.
  final int? total;

  const DigimonPage(this.digimon, {required this.hasNextPage, this.total});
}

/// Everything the app needs from the API, so view models and widgets never
/// talk to it directly.
abstract class DigimonRepository {
  static const int pageSize = 20;

  /// A page of the list, filtered by [query]. Each item already has its
  /// image, so cards need no further requests.
  Future<DigimonPage> getPage(int page, {DigimonQuery query = const DigimonQuery()});

  /// Details by id. Results are cached, so screens can ask freely.
  Future<DigimonDetails> getDetails(int id);

  /// Every Digimon (id, name, image) in API order, in one request (~220 KB),
  /// cached. Search runs over this list on the device.
  Future<List<Digimon>> getAll();

  /// Ids of every Digimon at [level] ("Child"), cached per level.
  Future<Set<int>> getIdsAtLevel(String level);

  /// Every level (Baby I … Ultimate, Armor, Hybrid, Unknown).
  Future<List<Lookup>> getLevels();

  /// Every attribute (Data, Vaccine, Virus, Free …).
  Future<List<Lookup>> getAttributes();
}

class ApiDigimonRepository implements DigimonRepository {
  /// Lookup endpoints page at 5; stop here in case the API never ends.
  static const int _maxLookupPages = 20;
  static const int _maxCachedDetails = 300;

  /// More than the API's total, so one page holds everything.
  static const int _everything = 5000;

  final RestClient _client;
  final Map<int, Future<DigimonDetails>> _details = {};
  Future<List<Lookup>>? _levels;
  Future<List<Lookup>>? _attributes;
  Future<List<Digimon>>? _all;
  final Map<String, Future<Set<int>>> _levelIds = {};

  ApiDigimonRepository(this._client);

  Future<List<Digimon>> _fetchAll({String? level}) async {
    final content = await _client.getPaginatedDigimon(0, pageSize: _everything, level: level);
    return (content.content ?? const []).map(Digimon.$DigimonFromJson).where((d) => d.id != null).toList();
  }

  @override
  Future<List<Digimon>> getAll() => _all ??= _fetchAll().catchError((Object e) {
        _all = null; // let a later request retry
        throw e;
      });

  @override
  Future<Set<int>> getIdsAtLevel(String level) => _levelIds[level] ??= _fetchAll(level: level).then((all) => all.map((d) => d.id!).toSet()).catchError((Object e) {
        _levelIds.remove(level);
        throw e;
      });

  @override
  Future<DigimonPage> getPage(int page, {DigimonQuery query = const DigimonQuery()}) async {
    final Content content = await _client.getPaginatedDigimon(
      page,
      pageSize: DigimonRepository.pageSize,
      name: query.name,
      attribute: query.attribute,
      level: query.level,
      xAntibody: query.xAntibody,
    );
    final digimon = (content.content ?? const []).map(Digimon.$DigimonFromJson).where((d) => d.id != null).toList();
    return DigimonPage(digimon, hasNextPage: content.hasNextPage, total: content.totalElements);
  }

  @override
  Future<DigimonDetails> getDetails(int id) {
    final hit = _details.remove(id);
    if (hit != null) return _details[id] = hit; // most recently used goes last
    if (_details.length >= _maxCachedDetails) _details.remove(_details.keys.first);
    return _details[id] = _client.getDigimon('$id').catchError((Object e) {
      _details.remove(id); // let a later request retry
      throw e;
    });
  }

  @override
  Future<List<Lookup>> getLevels() => _levels ??= _allLookups(_client.getLevels).catchError((Object e) {
        _levels = null;
        throw e;
      });

  @override
  Future<List<Lookup>> getAttributes() => _attributes ??= _allLookups(_client.getAttributes).catchError((Object e) {
        _attributes = null;
        throw e;
      });

  static Future<List<Lookup>> _allLookups(Future<LookupPage> Function(int page) fetch) async {
    final all = <Lookup>[];
    for (var page = 0; page < _maxLookupPages; page++) {
      final result = await fetch(page);
      all.addAll(result.items);
      if (!result.hasNextPage) break;
    }
    return all;
  }
}
