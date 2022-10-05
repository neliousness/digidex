import 'package:palette_generator/palette_generator.dart';

import '../components/digimon_card.dart';
import '../models/digimon.dart';
import '../models/digimon_details.dart';
import '../utils/constants.dart';
import '../utils/digimon_utils.dart';
import '../utils/retro-client.dart';
import 'base_view_model.dart';

class DigimonViewModel extends BaseViewModel {
  late RestClient client;
  Map<String, PaletteGenerator> paletteMap = {};

  List<DigimonCard> _digimon = [];

  List<DigimonCard> get digimon => _digimon;

  late PaletteGenerator _paletteGenerator;

  PaletteGenerator get paletteGenerator => _paletteGenerator;

  bool _loading = false;

  bool get loading => _loading;

  init(RestClient client) {
    this.client = client;
  }

  loadData(int page) async {
    _loading = true;
    client.getPaginatedDigimon(page).then((values) {
      values.content?.forEach((element) {
        print("content $element");
        Digimon item = Digimon.$DigimonFromJson(element);
        client.getDigimon("${item.id}").then((details) => _getPaletteGenerator(details));
      });
    });
  }

  _getPaletteGenerator(DigimonDetails details) async {
    final image = details.images?[0][kHref];
    Future<PaletteGenerator?> gen = !paletteMap.containsKey(image) ? DigimonUtils.generatePalette(details) : _localGen(image);
    gen.then((palette) => _listBuilder(DigiData(palette!, details)));
  }

  _listBuilder(DigiData data) async {
    DigimonDetails details = data.details;
    PaletteGenerator generator = data.generator;

    final image = details.images?[0][kHref];
    paletteMap[image] = generator;

    _digimon.add(DigimonCard(
      client: client,
      paletteGenerator: generator,
      details: details,
      imageLink: image,
    ));

    if (_digimon.length == 1) {
      _paletteGenerator = generator;
    }
    _digimon = _digimon.toSet().toList();
    _loading = false;

    notifyListeners();
  }

  Future<PaletteGenerator?> _localGen(String href) async {
    return paletteMap[href];
  }
}

class DigiData {
  PaletteGenerator _generator;
  DigimonDetails _details;

  DigiData(this._generator, this._details);

  DigimonDetails get details => _details;

  PaletteGenerator get generator => _generator;
}
