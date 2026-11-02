/// Filters for the Digimon list. Null fields aren't sent to the API.
class DigimonQuery {
  /// Matches anywhere in the name ("gre" finds Greymon).
  final String? name;
  final String? attribute;
  final String? level;
  final bool? xAntibody;

  const DigimonQuery({this.name, this.attribute, this.level, this.xAntibody});

  bool get isEmpty => name == null && attribute == null && level == null && xAntibody == null;

  DigimonQuery withName(String? name) {
    final trimmed = name?.trim();
    return DigimonQuery(name: trimmed == null || trimmed.isEmpty ? null : trimmed, attribute: attribute, level: level, xAntibody: xAntibody);
  }

  @override
  bool operator ==(Object other) =>
      other is DigimonQuery && other.name == name && other.attribute == attribute && other.level == level && other.xAntibody == xAntibody;

  @override
  int get hashCode => Object.hash(name, attribute, level, xAntibody);
}
