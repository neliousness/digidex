import 'constants.dart';

class DigimonUtils {
  static bool isValidEvolution(dynamic evolution) {
    return evolution is Map && evolution[kId] != null && evolution[kDigimon] != null;
  }

  static String getDescription(List<dynamic>? descriptions, String language) {
    final match = descriptions?.whereType<Map>().where((element) => element['language'] == language);
    final description = (match == null || match.isEmpty) ? null : match.first['description'];
    return description is String && description.isNotEmpty ? description : kNA;
  }

  static String formattedName(String name) {
    if (name.contains("(X-Antibody)")) {
      return name.replaceAll("(X-Antibody)", "");
    }
    return name;
  }
}
