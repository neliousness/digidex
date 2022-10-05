import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import '../models/digimon_details.dart';
import 'constants.dart';

class DigimonUtils {
  static Future<PaletteGenerator?> generatePalette(DigimonDetails? details) async {
    String href = details?.images?[0][kHref];
    NetworkImage image = NetworkImage(href);
    return await PaletteGenerator.fromImageProvider(
      image,
      region: Offset.zero & Size(250, 250),
      size: Size(250, 250),
      maximumColorCount: 20,
    );
  }

  static isValidEvolution(dynamic evolution) {
    return evolution[kId] != null && evolution[kDigimon] != null;
  }

  static getDescription(List<dynamic>? descriptions, String language) {
    try {
      var description = descriptions!.isNotEmpty ? descriptions.where((element) => element['language'] == language).first['description'] : null;
      return description != null ? description : "N/A";
    } catch (e) {
      return "N/A";
    }
  }

  static String formattedName(String name) {
    if (name.contains("(X-Antibody)")) {
      return name.replaceAll("(X-Antibody)", "");
    }
    return name;
  }
}
