import 'package:palette_generator/palette_generator.dart';

import '../models/digimon_details.dart';
import '../utils/constants.dart';
import '../utils/digimon_utils.dart';
import '../utils/retro-client.dart';
import 'base_view_model.dart';
import 'digimon_viewmodel.dart';

class DigimonSingleViewModel extends BaseViewModel {
  late RestClient client;

  init(RestClient client) {
    this.client = client;
  }

  getSingleDigimonByName(String name) {
    client.getDigimon(name).then((details) => _getSinglePaletteGenerator(details)).onError((error, stackTrace) => postValue(DigiData(null, null)));
  }

  _getSinglePaletteGenerator(DigimonDetails details) async {
    final image = details.images?[0][kHref];
    Future<PaletteGenerator?> gen = !DigimonUtils.paletteMap.containsKey(image) ? DigimonUtils.generatePalette(details) : _localGen(image);
    gen.then((palette) => postValue(DigiData(palette!, details, search: true)));
  }

  Future<PaletteGenerator?> _localGen(String href) async {
    return DigimonUtils.paletteMap[href];
  }
}
