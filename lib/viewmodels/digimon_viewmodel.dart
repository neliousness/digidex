import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import '../models/digimon.dart';
import '../models/digimon_details.dart';
import '../utils/digimon_utils.dart';
import '../utils/retro-client.dart';
import 'base_view_model.dart';

class DigimonViewModel extends BaseViewModel {
  late RestClient client;
  Map<String, PaletteGenerator> paletteMap = {};

  init(RestClient client) {
    this.client = client;
  }

  loadData(int page) async {
    client.getPaginatedDigimon(page).then((values) {
      values.content?.forEach((element) {
        print("content $element");
        Digimon item = Digimon.$DigimonFromJson(element);
        client.getDigimon("${item.id}").then((details) => _getPaletteGenerator(details));
      });
    });
  }

  _getPaletteGenerator(DigimonDetails details) async {
    final image = details.images?[0]['href'];
    Future<PaletteGenerator?> gen = !paletteMap.containsKey(image) ? DigimonUtils.generatePalette(details) : _localGen(image);
    gen.then((palette) => postValue(DigiData(palette!, details)));
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
