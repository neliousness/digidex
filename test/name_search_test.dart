import 'package:digidexplus/models/digimon.dart';
import 'package:digidexplus/utils/name_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final all = [
    Digimon(id: 1, name: 'Agumon'),
    Digimon(id: 34, name: 'Greymon'),
    Digimon(id: 396, name: 'Greymon (Blue)'),
    Digimon(id: 730, name: 'Greymon (X-Antibody)'),
    Digimon(id: 169, name: 'Metal Greymon'),
    Digimon(id: 240, name: 'Great King Sukamon'),
    Digimon(id: 11, name: "Deathmon (C'mon Digimon Version)"),
    Digimon(id: 80, name: 'Blue Meramon'),
    Digimon(id: 1001, name: 'Agumon (Black)'),
  ];
  final search = NameSearch(all);
  List<int?> ids(String q, {Set<int>? only}) => search.search(q, onlyIds: only).map((d) => d.id).toList();

  group('NameSearch', () {
    test('ignores case and surrounding spaces', () {
      expect(ids('GREY'), ids('grey'));
      expect(ids('  grey  '), ids('grey'));
    });

    test('finds what the API filter misses: inside brackets and mid-word', () {
      expect(ids('blue'), containsAll([80, 396]));
      expect(ids('antibody'), [730]);
      expect(ids('eymon'), containsAll([34, 396, 730, 169]));
    });

    test('ignores punctuation and spacing differences', () {
      expect(ids('x antibody'), [730]);
      expect(ids('x-antibody'), [730]);
      expect(ids("c'mon"), [11]);
      expect(ids('cmon'), [11]);
      expect(ids('metalgrey'), [169]);
      expect(ids('greymon (blue)'), [396]);
    });

    test('ranks name starts, then word starts, then anywhere', () {
      // "Greymon…" and "Great…" start with it; "Metal Greymon" has a word starting with it.
      expect(ids('gre'), [34, 396, 730, 240, 169]);
      expect(ids('blue'), [80, 396], reason: '"Blue Meramon" starts with it');
    });

    test('a number or #number finds that id first', () {
      expect(ids('1').first, 1);
      expect(ids('#001').first, 1);
      expect(ids('# 34'), [34]);
    });

    test('empty and junk queries', () {
      expect(ids(''), hasLength(all.length));
      expect(ids('   '), hasLength(all.length));
      expect(ids('%'), isEmpty, reason: 'no letters or digits: no name can match');
      expect(ids('zzz'), isEmpty);
      expect(ids('日本'), isEmpty);
    });

    test('combines with a level filter', () {
      expect(ids('grey', only: {396, 169}), [396, 169]);
      expect(ids('', only: {1}), [1]);
      expect(ids('grey', only: {}), isEmpty);
    });
  });
}
