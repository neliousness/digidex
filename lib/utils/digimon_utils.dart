import 'package:digidexplus/utils/retro-client.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import '../models/digimon_details.dart';

class DigimonUtils {
  static Future<PaletteGenerator?> generatePalette(DigimonDetails? details) async {
    String href = details?.images?[0]['href'];
    NetworkImage image = NetworkImage(href);
    return await PaletteGenerator.fromImageProvider(
      image,
      region: Offset.zero & Size(250, 250),
      size: Size(250, 250),
      maximumColorCount: 20,
    );
  }

  static isValidEvolution(dynamic evolution) {
    return evolution['id'] != null && evolution['digimon'] != null;
  }

  static getDescription(List<dynamic>? descriptions, String language) {
    var description = descriptions!.isNotEmpty ? descriptions.where((element) => element['language'] == language).first['description'] : null;
    return description != null ? description : "N/A";
  }
}
