import 'package:json_annotation/json_annotation.dart';

import '../utils/constants.dart';

@JsonSerializable()
class Digimon {
  int? id;
  String? name;
  String? href;

  Digimon({this.id = -1, this.name = "N/A", this.href = "N/A"});

  @override
  bool operator ==(Object other) {
    return other != null && other is Digimon && hashCode == other.hashCode;
  }

  @override
  int get hashCode => id!;

  static $DigimonFromJson(dynamic json) {
    if (json != null) {
      return Digimon(id: json[kId], name: json[kName], href: json[kHref]);
    }
    return Digimon();
  }
}
