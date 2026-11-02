import 'package:digidexplus/viewmodels/digimon_single_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_digimon_repository.dart';

void main() {
  group('DigimonSingleViewModel', () {
    test('loads details by id', () async {
      final repo = FakeDigimonRepository(details: {1: detailsFor(1, name: 'Agumon', level: 'Child')});
      final model = DigimonSingleViewModel(repo, digimon(1, 'Agumon'));

      final load = model.load();
      expect(model.loading, isTrue);
      await load;

      expect(model.loading, isFalse);
      expect(model.failed, isFalse);
      expect(model.details?.primaryLevel, 'Child');
      expect(repo.detailRequests, [1]);
    });

    test('reports failure and can retry', () async {
      final repo = FakeDigimonRepository()..detailsError = StateError('offline');
      final model = DigimonSingleViewModel(repo, digimon(1));

      await model.load();
      expect(model.failed, isTrue);
      expect(model.details, isNull);

      repo.detailsError = null;
      await model.load();
      expect(model.failed, isFalse);
      expect(model.details?.id, 1);
    });

    test('loads only once', () async {
      final repo = FakeDigimonRepository();
      final model = DigimonSingleViewModel(repo, digimon(1));

      await Future.wait([model.load(), model.load()]);
      await model.load();

      expect(repo.detailRequests, [1]);
    });
  });
}
