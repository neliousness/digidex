import 'dart:math';

import 'package:digidexplus/viewmodels/home_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_digimon_repository.dart';

void main() {
  final catalogue = List.generate(60, (i) => digimon(i + 1));
  const ahead = HomeViewModel.lookAhead;

  group('HomeViewModel', () {
    test('deals different random Digimon on both sides of the centre, off screen too', () async {
      final model = HomeViewModel(FakeDigimonRepository(catalogue: catalogue), random: Random(1));

      await model.deal();

      expect(model.total, 60);
      final ids = [for (var i = -ahead; i <= ahead; i++) model.cardAt(i)!.id!];
      expect(ids.toSet(), hasLength(2 * ahead + 1));
      expect(ids.every((id) => id >= 1 && id <= 60), isTrue);
      expect(model.selectedSlot, 0, reason: 'the middle slot starts selected');
      expect(model.drawnIndex, 0);
    });

    test('tapping a card selects its slot and draws it', () async {
      final model = HomeViewModel(FakeDigimonRepository(catalogue: catalogue), random: Random(2));
      await model.deal();

      model.select(-2, slot: -2);

      expect(model.selectedSlot, -2);
      expect(model.drawnIndex, -2);
      expect(model.drawnCard, same(model.cardAt(-2)));
      expect(model.draws, 1);
    });

    test('scrolling keeps the selected slot, so the next card in it is drawn', () async {
      final model = HomeViewModel(FakeDigimonRepository(catalogue: catalogue), random: Random(3));
      await model.deal();
      model.select(1, slot: 1);

      model.scrollTo(1);
      expect(model.drawnIndex, 2, reason: 'the card one to the right moved into slot 1');
      model.scrollTo(-3);
      expect(model.drawnIndex, -2);
      expect(model.selectedSlot, 1);
      expect(model.draws, 1, reason: 'scrolling is not a tap');
    });

    test('scrolling fetches cards ahead of the hand', () async {
      final repo = FakeDigimonRepository(catalogue: catalogue);
      final model = HomeViewModel(repo, random: Random(4));
      await model.deal();
      final before = repo.detailRequests.length;

      model.scrollTo(10);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repo.detailRequests.length, before + 10, reason: 'positions ${ahead + 1}..${10 + ahead} are new');
      expect(model.cardAt(10 + ahead), isNotNull);
    });

    test('a catalogue smaller than the hand still deals', () async {
      final model = HomeViewModel(FakeDigimonRepository(catalogue: catalogue.take(3).toList()), random: Random(5));
      await model.deal().timeout(const Duration(seconds: 2));
      expect([for (var i = -3; i <= 3; i++) model.cardAt(i)].whereType<Object>(), hasLength(7));
    });

    test('cards whose details fail are retried with another id, else left empty', () async {
      final repo = FakeDigimonRepository(catalogue: catalogue)..detailsError = StateError('offline');
      final model = HomeViewModel(repo, random: Random(6));

      await model.deal();

      expect(model.cardAt(0), isNull);
      expect(repo.detailRequests, hasLength((2 * ahead + 1) * 3));
    });

    test('uses the known total when the list call fails', () async {
      final repo = FakeDigimonRepository(catalogue: catalogue)..pageError = StateError('offline');
      final model = HomeViewModel(repo, random: Random(7));
      await model.deal();
      expect(model.total, isNull);
      expect(model.cardAt(0), isNotNull);
    });
  });
}
