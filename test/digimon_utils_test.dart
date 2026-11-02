import 'package:digidexplus/utils/constants.dart';
import 'package:digidexplus/utils/digimon_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DigimonUtils.formattedName', () {
    test('removes the X-Antibody suffix', () {
      expect(DigimonUtils.formattedName('Agumon(X-Antibody)'), 'Agumon');
    });

    test('leaves other names alone', () {
      expect(DigimonUtils.formattedName('Agumon'), 'Agumon');
    });
  });

  group('DigimonUtils.getDescription', () {
    final descriptions = [
      {'language': 'jap', 'description': 'ジャ'},
      {'language': 'en_us', 'description': 'A reptile Digimon.'},
    ];

    test('picks the requested language', () {
      expect(DigimonUtils.getDescription(descriptions, 'en_us'), 'A reptile Digimon.');
    });

    test('falls back to N/A when missing', () {
      expect(DigimonUtils.getDescription(descriptions, 'fr'), kNA);
      expect(DigimonUtils.getDescription([], 'en_us'), kNA);
      expect(DigimonUtils.getDescription(null, 'en_us'), kNA);
      expect(DigimonUtils.getDescription([{'language': 'en_us', 'description': null}], 'en_us'), kNA);
      expect(DigimonUtils.getDescription(['not a map'], 'en_us'), kNA);
    });
  });

  group('DigimonUtils.isValidEvolution', () {
    test('needs both an id and a name', () {
      expect(DigimonUtils.isValidEvolution({'id': 1, 'digimon': 'Greymon'}), isTrue);
      expect(DigimonUtils.isValidEvolution({'id': null, 'digimon': 'Greymon'}), isFalse);
      expect(DigimonUtils.isValidEvolution({'id': 1}), isFalse);
      expect(DigimonUtils.isValidEvolution(null), isFalse);
    });
  });
}
