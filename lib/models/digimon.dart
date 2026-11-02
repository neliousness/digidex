import '../utils/constants.dart';

/// A Digimon as the list endpoint returns it: enough to draw a card.
class Digimon {
  int? id;
  String? name;
  String? href;
  String? image;

  Digimon({this.id = -1, this.name = kNA, this.href = kNA, this.image});

  @override
  bool operator ==(Object other) {
    return other is Digimon && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;

  static Digimon $DigimonFromJson(dynamic json) {
    if (json != null) {
      final image = json[kImage];
      return Digimon(id: json[kId], name: json[kName], href: json[kHref], image: image is String && image.isNotEmpty ? image : null);
    }
    return Digimon();
  }
}
