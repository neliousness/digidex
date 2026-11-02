import 'package:digidexplus/viewmodels/browse_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_digimon_repository.dart';

void main() {
  final catalogue = [digimon(1, 'Agumon'), digimon(34, 'Greymon'), digimon(396, 'Greymon (Blue)'), digimon(169, 'Metal Greymon'), digimon(16, 'Gabumon')];
  List<int?> ids(BrowseViewModel m) => m.results.map((d) => d.id).toList();

  FakeDigimonRepository repo() => FakeDigimonRepository(catalogue: catalogue)..levels.addAll({1: 'Child', 16: 'Child', 34: 'Adult', 396: 'Adult', 169: 'Perfect'});

  group('BrowseViewModel', () {
    test('loads the full list once and shows everything', () async {
      final r = repo();
      final model = BrowseViewModel(r);
      await Future.wait([model.load(), model.load()]);
      await model.load();

      expect(r.allRequests, 1);
      expect(model.total, 5);
      expect(ids(model), [1, 34, 396, 169, 16]);
      expect(model.filtered, isFalse);
    });

    test('search updates instantly, including matches the API would miss', () async {
      final model = BrowseViewModel(repo());
      await model.load();

      model.setQuery('blue');
      expect(ids(model), [396]);
      model.setQuery('GREY');
      expect(ids(model), [34, 396, 169]);
      model.setQuery('');
      expect(ids(model), hasLength(5));
    });

    test('rapid typing always shows the latest query', () async {
      final model = BrowseViewModel(repo());
      await model.load();
      for (final q in ['g', 'gr', 'gre', 'grey', 'greym', 'gab']) {
        model.setQuery(q);
      }
      expect(ids(model), [16]);
    });

    test('a level filter combines with the search', () async {
      final model = BrowseViewModel(repo());
      await model.load();

      final pending = model.setLevel('Adult');
      expect(model.loading, isTrue, reason: 'the level ids are loading');
      expect(model.noResults, isFalse, reason: 'not "nothing found" while loading');
      await pending;

      expect(ids(model), [34, 396]);
      model.setQuery('blue');
      expect(ids(model), [396]);
      model.setQuery('agu');
      expect(model.noResults, isTrue);

      await model.setLevel(null);
      expect(ids(model), [1]);
    });

    test('the latest level chip wins', () async {
      final model = BrowseViewModel(repo());
      await model.load();
      final adult = model.setLevel('Adult');
      final child = model.setLevel('Child');
      await Future.wait([adult, child]);
      expect(model.level, 'Child');
      expect(ids(model), [1, 16]);
    });

    test('offline: failed, then retry recovers', () async {
      final r = repo()..pageError = StateError('offline');
      final model = BrowseViewModel(r);
      await model.load();
      expect(model.failed, isTrue);
      expect(model.noResults, isFalse, reason: 'offline is not "nothing found"');

      r.pageError = null;
      await model.retry();
      expect(model.failed, isFalse);
      expect(ids(model), hasLength(5));
    });

    test('searching before the list arrives applies once it does', () async {
      final r = FakeDigimonRepository(catalogue: catalogue, holdPages: true);
      final model = BrowseViewModel(r);
      final load = model.load();
      model.setQuery('gab');
      expect(model.results, isEmpty);
      expect(model.noResults, isFalse);
      r.releasePage(0);
      await load;
      expect(ids(model), [16]);
    });
  });
}
