import '../utils/constants.dart';
import '../utils/digimon_utils.dart';

/// A link from one Digimon to a prior or next evolution.
class EvolutionLink {
  final int id;
  final String name;
  final bool isNext;
  final String? imageUrl;

  /// How the evolution happens ("With or without Gabumon"), or empty.
  final String condition;

  const EvolutionLink({required this.id, required this.name, required this.isNext, this.imageUrl, this.condition = ''});
}

class DigimonDetails {
  int? id;
  String? name;
  bool? xAntibody;
  String? releaseDate;
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
      this.releaseDate,
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

  static DigimonDetails $DigimonDetailsFromJson(dynamic json) {
    if (json != null) {
      final name = json[kName];
      return DigimonDetails(
        id: json[kId],
        name: name is String ? DigimonUtils.formattedName(name) : null,
        xAntibody: json['xAntibody'],
        releaseDate: json['releaseDate'] == null ? null : '${json['releaseDate']}',
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

  /// The first image's url, or null when the API has no image for this Digimon.
  String? get imageUrl => _firstValue(images, kHref);

  String get primaryType => _firstValue(types, 'type') ?? kNA;

  String get primaryLevel => _firstValue(levels, 'level') ?? kNA;

  String get primaryAttribute => _firstValue(attributes, 'attribute') ?? kNA;

  /// Next evolutions first, then prior ones, each Digimon only once (the API
  /// lists some more than once, and repeated Hero images would crash).
  List<EvolutionLink> get evolutions {
    final seen = <int>{};
    final links = <EvolutionLink>[];
    void addAll(List<dynamic>? list, bool isNext) {
      for (final element in list ?? const []) {
        if (!DigimonUtils.isValidEvolution(element)) continue;
        final id = element[kId];
        if (id is int && seen.add(id) && id != this.id) {
          final image = element[kImage];
          final condition = element['condition'];
          links.add(EvolutionLink(
            id: id,
            name: '${element[kDigimon]}',
            isNext: isNext,
            imageUrl: image is String && image.isNotEmpty ? image : null,
            condition: condition is String ? condition.trim() : '',
          ));
        }
      }
    }

    addAll(nextEvolutions, true);
    addAll(priorEvolutions, false);
    return links;
  }

  static String? _firstValue(List<dynamic>? list, String key) {
    if (list == null || list.isEmpty || list.first is! Map) return null;
    final value = list.first[key];
    return value == null ? null : '$value';
  }
}
