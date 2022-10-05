import 'package:digidexplus/utils/constants.dart';
import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class DigimonDetails {
  int? id;
  String? name;
  bool? xAntibody;
  List<dynamic>? images;
  List<dynamic>? types;
  List<dynamic>? levels;
  List<dynamic>? attributes;
  List<dynamic>? fields;
  List<dynamic>? descriptions;
  List<dynamic>? skills;
  List<dynamic>? nextEvolutions;
  List<dynamic>? priorEvolutions;

  DigimonDetails(
      {this.id,
      this.name,
      this.xAntibody,
      this.images,
      this.types,
      this.levels,
      this.attributes,
      this.fields,
      this.descriptions,
      this.skills,
      this.nextEvolutions,
      this.priorEvolutions});

  factory DigimonDetails.fromJson(Map<String, dynamic> json) => $DigimonDetailsFromJson(json);

  static $DigimonDetailsFromJson(dynamic json) {
    if (json != null) {
      return DigimonDetails(
        id: json[kId],
        name: json[kName],
        xAntibody: json['xAntibody'],
        images: json['images'],
        types: json['types'],
        levels: json['levels'],
        attributes: json['attributes'],
        fields: json['fields'],
        descriptions: json['descriptions'],
        skills: json['skills'],
        priorEvolutions: json['priorEvolutions'],
        nextEvolutions: json['nextEvolutions'],
      );
    }
    return DigimonDetails();
  }
}
