import 'dart:async';

import 'package:digidexplus/data/digimon_repository.dart';
import 'package:digidexplus/models/digimon.dart';
import 'package:digidexplus/models/digimon_details.dart';
import 'package:digidexplus/models/digimon_query.dart';
import 'package:digidexplus/models/lookup.dart';

Digimon digimon(int id, [String? name]) => Digimon(id: id, name: name ?? 'Digimon $id', image: 'https://example.com/$id.png');

DigimonDetails detailsFor(int id, {String? name, String? level, String? attribute}) => DigimonDetails(
      id: id,
      name: name ?? 'Digimon $id',
      images: [{'href': 'https://example.com/$id.png'}],
      levels: level == null ? const [] : [{'id': 1, 'level': level}],
      attributes: attribute == null ? const [] : [{'id': 1, 'attribute': attribute}],
    );

/// An in-memory [DigimonRepository] that pages and filters [catalogue] the
/// way the API does (name matches anywhere, case-insensitive).
///
/// With [holdPages] set, page requests wait until the test calls
/// [releasePage], so tests decide when (and in which order) they answer.
class FakeDigimonRepository implements DigimonRepository {
  final List<Digimon> catalogue;
  final Map<int, DigimonDetails> details;
  final int pageSize;
  final bool holdPages;

  FakeDigimonRepository({List<Digimon>? catalogue, Map<int, DigimonDetails>? details, this.pageSize = 2, this.holdPages = false})
      : catalogue = catalogue ?? [],
        details = details ?? {};

  final List<({int page, DigimonQuery query})> pageRequests = [];
  final List<Completer<void>> _heldPages = [];
  final List<int> detailRequests = [];
  Object? pageError;
  Object? detailsError;

  @override
  Future<DigimonPage> getPage(int page, {DigimonQuery query = const DigimonQuery()}) async {
    pageRequests.add((page: page, query: query));
    if (holdPages) {
      final hold = Completer<void>();
      _heldPages.add(hold);
      await hold.future;
    }
    if (pageError != null) throw pageError!;
    final name = query.name?.toLowerCase();
    final matches = catalogue.where((d) => name == null || (d.name ?? '').toLowerCase().contains(name)).toList();
    final start = page * pageSize;
    final items = start >= matches.length ? <Digimon>[] : matches.sublist(start, (start + pageSize).clamp(0, matches.length));
    return DigimonPage(items, hasNextPage: start + pageSize < matches.length, total: matches.length);
  }

  /// Answers the [index]th held page request (in the order they were made).
  void releasePage(int index) => _heldPages[index].complete();

  @override
  Future<DigimonDetails> getDetails(int id) async {
    detailRequests.add(id);
    if (detailsError != null) throw detailsError!;
    return details[id] ?? catalogueDetails(id) ?? detailsFor(id);
  }

  /// Details for a catalogue entry, so names match the list.
  DigimonDetails? catalogueDetails(int id) {
    final d = catalogue.where((d) => d.id == id).firstOrNull;
    return d == null ? null : detailsFor(id, name: d.name);
  }

  /// Levels for [getIdsAtLevel], by id. Unlisted ids have no level.
  final Map<int, String> levels = {};
  int allRequests = 0;

  @override
  Future<List<Digimon>> getAll() async {
    allRequests++;
    if (holdPages) {
      final hold = Completer<void>();
      _heldPages.add(hold);
      await hold.future;
    }
    if (pageError != null) throw pageError!;
    return List.of(catalogue);
  }

  @override
  Future<Set<int>> getIdsAtLevel(String level) async {
    if (pageError != null) throw pageError!;
    return {for (final e in levels.entries) if (e.value == level) e.key};
  }

  @override
  Future<List<Lookup>> getLevels() async => const [Lookup(4, 'Child'), Lookup(2, 'Adult')];

  @override
  Future<List<Lookup>> getAttributes() async => const [Lookup(4, 'Vaccine'), Lookup(3, 'Virus')];
}
