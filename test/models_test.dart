import 'package:digidexplus/models/content.dart';
import 'package:digidexplus/models/digimon.dart';
import 'package:digidexplus/models/digimon_details.dart';
import 'package:digidexplus/models/lookup.dart';
import 'package:digidexplus/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';

// Trimmed from a real https://digi-api.com/api/v1/digimon/agumon response.
final agumonJson = <String, dynamic>{
  'id': 1,
  'name': 'Agumon',
  'xAntibody': false,
  'releaseDate': '1997',
  'images': [
    {'href': 'https://digi-api.com/images/digimon/w/Agumon.png', 'transparent': false}
  ],
  'levels': [
    {'id': 4, 'level': 'Child'}
  ],
  'types': [
    {'id': 1, 'type': 'Reptile'}
  ],
  'attributes': [
    {'id': 4, 'attribute': 'Vaccine'}
  ],
  'fields': [
    {'id': 1, 'field': 'Metal Empire', 'image': 'https://digi-api.com/images/etc/fields/Metal_Empire.png'}
  ],
  'descriptions': [
    {'origin': 'reference_book', 'language': 'en_us', 'description': 'A reptile Digimon.'}
  ],
  'skills': [
    {'id': 1, 'skill': 'Baby Flame', 'translation': '', 'description': 'Spits fire.'}
  ],
  'priorEvolutions': [
    {'id': 2, 'digimon': 'Koromon', 'condition': '', 'image': '', 'url': ''},
  ],
  'nextEvolutions': [
    {'id': 3, 'digimon': 'Greymon', 'condition': '', 'image': 'https://digi-api.com/images/digimon/w/Greymon.png', 'url': ''},
    {'id': 3, 'digimon': 'Greymon', 'condition': 'again', 'image': '', 'url': ''},
    {'id': 1, 'digimon': 'Agumon', 'condition': 'itself', 'image': '', 'url': ''},
    {'id': null, 'digimon': 'Unknown', 'condition': '', 'image': '', 'url': ''},
  ],
};

void main() {
  group('DigimonDetails.fromJson', () {
    final agumon = DigimonDetails.fromJson(agumonJson);

    test('reads the fields the app shows', () {
      expect(agumon.id, 1);
      expect(agumon.name, 'Agumon');
      expect(agumon.xAntibody, isFalse);
      expect(agumon.imageUrl, 'https://digi-api.com/images/digimon/w/Agumon.png');
      expect(agumon.primaryType, 'Reptile');
      expect(agumon.primaryLevel, 'Child');
      expect(agumon.primaryAttribute, 'Vaccine');
      expect(agumon.releaseDate, '1997');
    });

    test('strips X-Antibody from the name', () {
      final x = DigimonDetails.fromJson({'id': 9, 'name': 'Agumon(X-Antibody)'});
      expect(x.name, 'Agumon');
    });

    test('survives missing or empty fields', () {
      final empty = DigimonDetails.fromJson({'id': 5, 'images': [], 'types': null});
      expect(empty.name, isNull);
      expect(empty.imageUrl, isNull);
      expect(empty.primaryType, kNA);
      expect(empty.primaryLevel, kNA);
      expect(empty.primaryAttribute, kNA);
      expect(empty.evolutions, isEmpty);
    });

    test('evolutions: next first, each Digimon once, no self or invalid links', () {
      final evolutions = agumon.evolutions;
      expect(evolutions.map((e) => e.id), [3, 2]);
      expect(evolutions.map((e) => e.name), ['Greymon', 'Koromon']);
      expect(evolutions.map((e) => e.isNext), [true, false]);
      expect(evolutions.map((e) => e.imageUrl), ['https://digi-api.com/images/digimon/w/Greymon.png', null]);
    });
  });

  group('Digimon', () {
    test('parses a list entry, image included', () {
      final digimon = Digimon.$DigimonFromJson({
        'id': 1,
        'name': 'Agumon',
        'href': 'https://digi-api.com/api/v1/digimon/1',
        'image': 'https://digi-api.com/images/digimon/w/Agumon.png',
      });
      expect(digimon.id, 1);
      expect(digimon.name, 'Agumon');
      expect(digimon.image, 'https://digi-api.com/images/digimon/w/Agumon.png');
    });

    test('a missing or empty image is null', () {
      expect(Digimon.$DigimonFromJson({'id': 1, 'image': ''}).image, isNull);
      expect(Digimon.$DigimonFromJson({'id': 1}).image, isNull);
    });

    test('is equal by id', () {
      expect(Digimon(id: 1, name: 'a'), Digimon(id: 1, name: 'b'));
      expect({Digimon(id: 1), Digimon(id: 1), Digimon(id: 2)}, hasLength(2));
    });

    test('null json gives a placeholder', () {
      expect(Digimon.$DigimonFromJson(null).id, -1);
    });
  });

  group('Content', () {
    test('has a next page while the API gives a nextPage url', () {
      final content = Content.fromJson({
        'content': [
          {'id': 1}
        ],
        'pageable': {'currentPage': 0, 'nextPage': 'https://digi-api.com/api/v1/digimon?page=1'},
      });
      expect(content.content, hasLength(1));
      expect(content.hasNextPage, isTrue);
    });

    test('has no next page when nextPage is empty, as on the last page', () {
      final content = Content.fromJson({
        'pageable': {'currentPage': 999, 'nextPage': ''},
      });
      expect(content.content, isNull);
      expect(content.hasNextPage, isFalse);
    });
  });

  group('LookupPage', () {
    test('reads the entries nested in content.fields', () {
      final page = LookupPage.fromJson({
        'content': {
          'name': 'Level',
          'fields': [
            {'id': 4, 'name': 'Child', 'href': 'https://digi-api.com/api/v1/level/4'},
            {'id': 2, 'name': 'Adult', 'href': 'https://digi-api.com/api/v1/level/2'},
          ],
        },
        'pageable': {'currentPage': 0, 'nextPage': 'https://digi-api.com/api/v1/level?page=1'},
      });
      expect(page.items.map((l) => l.name), ['Child', 'Adult']);
      expect(page.hasNextPage, isTrue);
    });

    test('ends on an empty nextPage or an empty page', () {
      expect(LookupPage.fromJson({'content': {'fields': [{'id': 1, 'name': 'Hybrid'}]}, 'pageable': {'nextPage': ''}}).hasNextPage, isFalse);
      // The API's totalPages is wrong, and past the end it can still give a nextPage.
      final empty = LookupPage.fromJson({'content': {'fields': []}, 'pageable': {'nextPage': 'https://digi-api.com/api/v1/level?page=3'}});
      expect(empty.items, isEmpty);
      expect(empty.hasNextPage, isFalse);
    });
  });
}
